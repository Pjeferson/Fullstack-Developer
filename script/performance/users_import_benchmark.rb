#!/usr/bin/env ruby
# frozen_string_literal: true

# Benchmarks the CPU-bound slice of the spreadsheet-import pipeline - CSV parsing
# (Imports::CsvParser), row validation (Imports::RowValidator), and attribute transformation
# (Imports::UserBatchInserter's own #attributes_for, reused via `send` rather than duplicated,
# since it's private) - across Ruby's execution modes (interpreter / YJIT / ZJIT). Deliberately
# excludes PostgreSQL, Solid Queue, Solid Cable, and file upload/network: those would make it
# impossible to tell whether a timing difference came from Ruby's execution engine or from
# something else entirely. See README's "Performance Profiling" section for the full write-up,
# including why bcrypt hashing is precomputed once rather than measured (a ~1.2s native crypto
# call on this machine - see "Limitations" there - that would swamp any signal from the
# Ruby-level work this benchmark actually targets).
#
# Usage:
#   ruby script/performance/users_import_benchmark.rb
#   ruby --yjit script/performance/users_import_benchmark.rb
#   ruby --zjit script/performance/users_import_benchmark.rb          # only if this Ruby build
#                                                                        has ZJIT compiled in
#   ruby --zjit --zjit-stats script/performance/users_import_benchmark.rb
#
#   ruby script/performance/users_import_benchmark.rb --compare       # prints a cross-mode
#                                                                        table from previously
#                                                                        saved runs, computes no
#                                                                        new numbers
#
#   END_TO_END=1 ruby script/performance/users_import_benchmark.rb    # also times a real
#                                                                        User.insert_all against
#                                                                        Postgres, rolled back -
#                                                                        opt-in, secondary to the
#                                                                        CPU-bound result above it

require_relative "../../config/environment"
require "benchmark/ips"
require "tempfile"
require "json"

module UsersImportBenchmark
  SIZES = [ 2_000, 5_000, 10_000 ].freeze
  RESULTS_DIR = Rails.root.join("tmp/performance")

  # attributes_for only ever reads import.id - a real SpreadsheetImport is unnecessary for the
  # CPU-bound benchmark, which never persists anything.
  FakeImport = Struct.new(:id)

  module_function

  def run
    if ARGV.include?("--compare")
      compare!
      return
    end

    puts header
    puts

    digest = BCrypt::Password.create(SecureRandom.hex(32)) # see file comment - not measured
    # Held in a local for the whole run - Tempfile unlinks its underlying file when the object
    # itself is garbage collected, which `generate_csv(size).path` alone doesn't prevent (the
    # Tempfile has no other reference once `.path` returns, so GC is free to reap it - and
    # occasionally did, mid-benchmark, before this held a real reference).
    files = SIZES.index_with { |size| generate_csv(size) }

    cpu_bound_results = SIZES.to_h do |size|
      report = Benchmark.ips do |x|
        x.config(warmup: 2, time: 5)
        x.report(label(size)) { process(files[size].path, digest) }
      end.entries.first

      [ size, entry_to_h(report) ]
    end

    save_results!("cpu_bound", cpu_bound_results)
    print_summary("CPU-bound (parse + validate + build attributes)", cpu_bound_results)

    if ENV["END_TO_END"]
      puts
      puts "End-to-end (real User.insert_all against Postgres, rolled back)"
      puts "-" * 70
      e2e_results = SIZES.to_h do |size|
        report = Benchmark.ips do |x|
          x.config(warmup: 1, time: 3)
          x.report(label(size)) { end_to_end(files[size].path) }
        end.entries.first

        [ size, entry_to_h(report) ]
      end
      save_results!("cpu_bound_end_to_end", e2e_results)
      print_summary("End-to-end (includes real persistence)", e2e_results)
    end
  ensure
    files&.each_value(&:close!)
  end

  # ~1% of rows deterministically leave full_name blank, so the benchmark exercises
  # Imports::RowValidator's failure path too - a real spreadsheet is essentially never 100%
  # clean. Deterministic (no Faker/random seed to manage) so the same input is reused across
  # every Ruby execution mode this is compared under.
  def generate_csv(count)
    file = Tempfile.new([ "users_import_benchmark_#{count}", ".csv" ])
    file.write("email_address,full_name,role\n")
    count.times do |i|
      n = i + 1
      full_name = (n % 97).zero? ? "" : "Benchmark User #{n}"
      role = (n % 10).zero? ? "admin" : ""
      file.write("user#{n}@example.com,#{full_name},#{role}\n")
    end
    file.flush
    file
  end

  # The CPU-bound slice this benchmark targets: parse -> validate -> build insert-ready
  # attributes. Stops short of Imports::UserBatchInserter#call's own User.insert_all line - the
  # one DB-bound part of that class, and the reason this isn't just `UserBatchInserter#call`
  # itself.
  def process(path, digest)
    rows = Imports::CsvParser.new(path).each_row.to_a
    inserter = Imports::UserBatchInserter.new([], import: FakeImport.new(0))

    valid = invalid = 0
    rows.each do |row|
      if Imports::RowValidator.new(row).valid?
        inserter.send(:attributes_for, row, digest)
        valid += 1
      else
        invalid += 1
      end
    end
    raise "no rows parsed - CSV generation is broken" if rows.empty?

    [ valid, invalid ]
  end

  # Opt-in (END_TO_END=1): the same parse+validate step, then a real
  # Imports::UserBatchInserter#call - including User.insert_all against Postgres. Wrapped in a
  # transaction that's always rolled back, so repeated iterations never accumulate data and
  # nothing is left behind if this is interrupted mid-run.
  def end_to_end(path)
    rows = Imports::CsvParser.new(path).each_row.to_a
    admin = User.admin.first!

    ActiveRecord::Base.transaction do
      import = SpreadsheetImport.create!(admin: admin)
      Imports::UserBatchInserter.new(rows, import: import).call
      raise ActiveRecord::Rollback
    end
  rescue ActiveRecord::RecordNotFound
    abort("END_TO_END=1 needs at least one admin User - run bin/rails db:seed first.")
  end

  def entry_to_h(entry)
    {
      ips: entry.ips,
      ms_per_iteration: 1000.0 / entry.ips,
      iterations: entry.iterations,
      error_percentage: entry.stats.error_percentage
    }
  end

  def label(size)
    "#{size.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\1,').reverse} rows"
  end

  def print_summary(title, results)
    puts
    puts title
    puts "-" * 70
    results.each do |size, r|
      printf("  %-12s %8.2f ms/iter  (%.0f i/s, ±%.1f%%, n=%d)\n",
        label(size), r[:ms_per_iteration], r[:ips], r[:error_percentage], r[:iterations])
    end
  end

  def current_mode
    if zjit_enabled?
      "zjit"
    elsif RubyVM::YJIT.enabled?
      "yjit"
    else
      "interpreter"
    end
  end

  # RubyVM::ZJIT is autoload-registered even in a Ruby build compiled without ZJIT support -
  # referencing it only raises once Ruby actually tries (and fails) to load the backing code, so
  # `defined?(RubyVM::ZJIT)` alone isn't enough to tell whether it's really usable here.
  def zjit_enabled?
    RubyVM::ZJIT.enabled?
  rescue NameError
    false
  end

  # --zjit-stats itself measurably slows a run down (confirmed by hand: the same workload timed
  # ~35-45% slower with it on than plain --zjit) - collecting those stats is for the profiling
  # investigation in the README, not a number that belongs next to interpreter/YJIT/plain-ZJIT
  # timings.
  def zjit_stats_enabled?
    RubyVM::ZJIT.respond_to?(:stats_enabled?) && RubyVM::ZJIT.stats_enabled?
  rescue NameError
    false
  end

  def header
    <<~TEXT
      Ruby execution mode: #{current_mode}
      #{RUBY_DESCRIPTION}
    TEXT
  end

  def save_results!(dataset, results)
    if zjit_stats_enabled?
      puts "(--zjit-stats is on - not saving these timings, see the comment on zjit_stats_enabled?)"
      return
    end

    RESULTS_DIR.mkpath
    payload = {
      mode: current_mode,
      ruby_description: RUBY_DESCRIPTION,
      recorded_at: Time.now.utc.iso8601,
      results: results.transform_keys(&:to_s)
    }
    RESULTS_DIR.join("#{dataset}-#{current_mode}.json").write(JSON.pretty_generate(payload))
  end

  # Reads whatever mode result files a prior run of this script already saved and prints a
  # cross-mode comparison - computes speedups from those saved numbers, never from numbers typed
  # in here. Plain string keys throughout (no symbolize_names) - one less thing to get wrong
  # matching JSON's own key types back up.
  def compare!
    %w[cpu_bound cpu_bound_end_to_end].each do |dataset|
      files = Dir.glob(RESULTS_DIR.join("#{dataset}-*.json")).sort
      next if files.empty?

      runs = files.each_with_object({}) do |f, hash|
        data = JSON.parse(File.read(f))
        hash[data["mode"]] = data
      end

      puts dataset == "cpu_bound" ? "CPU-bound (parse + validate + build attributes)" : "End-to-end (includes real persistence)"
      puts "=" * 70

      SIZES.each do |size|
        key = size.to_s
        next unless runs.values.any? { |run| run["results"][key] }

        puts "\n#{label(size)}"
        baseline = runs.dig("interpreter", "results", key)
        yjit_entry = runs.dig("yjit", "results", key)
        %w[interpreter yjit zjit].each do |mode|
          entry = runs.dig(mode, "results", key)
          next unless entry

          line = format("  %-12s %8.2f ms/iter  (%.0f i/s)", mode, entry["ms_per_iteration"], entry["ips"])
          if baseline && mode != "interpreter"
            speedup = (baseline["ms_per_iteration"] / entry["ms_per_iteration"] - 1) * 100
            line += format("   %+.1f%% vs interpreter", speedup)
          end
          if mode == "zjit" && yjit_entry
            speedup = (yjit_entry["ms_per_iteration"] / entry["ms_per_iteration"] - 1) * 100
            line += format("   %+.1f%% vs yjit", speedup)
          end
          puts line
        end
      end
      puts
    end

    if Dir.glob(RESULTS_DIR.join("*.json")).empty?
      puts "No saved results yet - run the benchmark under each mode first, e.g.:"
      puts "  ruby script/performance/users_import_benchmark.rb"
      puts "  ruby --yjit script/performance/users_import_benchmark.rb"
      puts "  ruby --zjit script/performance/users_import_benchmark.rb"
    end
  end
end

UsersImportBenchmark.run if $PROGRAM_NAME == __FILE__
