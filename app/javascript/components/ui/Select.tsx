import { Listbox, ListboxButton, ListboxLabel, ListboxOption, ListboxOptions } from '@headlessui/react'
import { Check, ChevronDown } from 'lucide-react'

type Option = { value: string; label: string }

type Props = {
  label: string
  value: string
  onChange: (value: string) => void
  options: Option[]
}

// A styled replacement for a native <select> - cross-browser styling of native selects is
// inconsistent, and Headless UI's Listbox gives keyboard navigation and ARIA semantics for free.
export default function Select({ label, value, onChange, options }: Props) {
  const selected = options.find((option) => option.value === value)

  return (
    <Listbox value={value} onChange={onChange}>
      <ListboxLabel className="block text-sm font-medium text-text">{label}</ListboxLabel>
      <div className="relative mt-1">
        <ListboxButton className="relative w-full cursor-default rounded-md border border-border bg-surface py-2 pl-3 pr-10 text-left text-sm shadow-sm focus:border-primary focus:outline-none focus:ring-1 focus:ring-primary">
          <span className="block truncate">{selected?.label ?? ''}</span>
          <span className="pointer-events-none absolute inset-y-0 right-0 flex items-center pr-2">
            <ChevronDown className="h-4 w-4 text-text-muted" aria-hidden="true" />
          </span>
        </ListboxButton>
        <ListboxOptions
          anchor="bottom start"
          className="z-10 mt-1 w-(--button-width) overflow-auto rounded-md bg-surface py-1 text-sm shadow-lg ring-1 ring-black/5 focus:outline-none"
        >
          {options.map((option) => (
            <ListboxOption
              key={option.value}
              value={option.value}
              className="relative cursor-default select-none py-2 pl-10 pr-4 data-[focus]:bg-primary/10"
            >
              {({ selected: isSelected }) => (
                <>
                  <span className={`block truncate ${isSelected ? 'font-semibold' : 'font-normal'}`}>
                    {option.label}
                  </span>
                  {isSelected && (
                    <span className="absolute inset-y-0 left-0 flex items-center pl-3 text-primary">
                      <Check className="h-4 w-4" aria-hidden="true" />
                    </span>
                  )}
                </>
              )}
            </ListboxOption>
          ))}
        </ListboxOptions>
      </div>
    </Listbox>
  )
}
