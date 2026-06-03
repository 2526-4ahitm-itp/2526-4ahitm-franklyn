<script setup lang="ts" generic="T extends string">
import { computed } from 'vue'
import {
  SelectContent,
  SelectItem,
  SelectItemText,
  SelectPortal,
  SelectRoot,
  SelectTrigger,
  SelectValue,
  SelectViewport,
} from 'reka-ui'

export interface DropdownItem<T = string> {
  value: T
  label: string
  icon?: string
}

interface Props {
  items: DropdownItem<T>[]
  placeholder?: string
  ariaLabel?: string
}

const props = defineProps<Props>()

const modelValue = defineModel<T>({ required: true })

const selectedItem = computed(() => {
  return props.items.find((item) => item.value === modelValue.value)
})

const selectedIcon = computed(() => {
  return selectedItem.value?.icon
})
</script>

<template>
  <SelectRoot v-model="modelValue">
    <SelectTrigger class="dropdown-trigger" :aria-label="ariaLabel">
      <i v-if="selectedIcon" :class="selectedIcon"></i>
      <SelectValue class="dropdown-value" :placeholder="placeholder" />
      <i class="bi bi-chevron-down chevron"></i>
    </SelectTrigger>

    <SelectPortal>
      <SelectContent class="ds-menu" position="popper" align="end" :side-offset="8">
        <SelectViewport class="ds-viewport">
          <SelectItem
            v-for="item in items"
            :key="item.value"
            class="ds-item"
            :value="item.value"
          >
            <i v-if="item.icon" :class="item.icon"></i>
            <SelectItemText>{{ item.label }}</SelectItemText>
          </SelectItem>
        </SelectViewport>
      </SelectContent>
    </SelectPortal>
  </SelectRoot>
</template>

<!-- Portal content teleports to document.body — scoped selectors cannot reach it.
     Vars are prefixed ds- (DropdownSelect) to prevent global collision. -->
<style>
.ds-menu {
  --ds-menu-bg: var(--bg-body);
  --ds-menu-border: var(--border-default);
  --ds-item-color: var(--text-secondary);
  --ds-item-hover-bg: var(--bg-input);
  --ds-item-checked-bg: var(--primary);
  --ds-item-checked-color: var(--color-on-primary);

  background: var(--ds-menu-bg);
  border: 1px solid var(--ds-menu-border);
  border-radius: var(--radius-lg);
  padding: var(--space-2);
  min-width: 160px;
  box-shadow: var(--shadow-modal);
  z-index: var(--z-modal);
}

.ds-viewport {
  display: flex;
  flex-direction: column;
  gap: var(--space-1);
  padding: 0;
}

.ds-item {
  background: transparent;
  border: none;
  color: var(--ds-item-color);
  padding: var(--space-2) var(--space-3);
  border-radius: var(--radius-md);
  cursor: pointer;
  text-align: left;
  display: flex;
  align-items: center;
  gap: var(--space-2);
  font-size: 0.95rem;
  font-weight: 500;
  width: 100%;
  box-sizing: border-box;
}

.ds-item[data-highlighted] {
  background: var(--ds-item-hover-bg);
  color: var(--text-primary);
}

.ds-item:focus-visible {
  outline: 2px solid var(--primary);
  outline-offset: -2px;
}

.ds-item[data-state='checked'] {
  background: var(--ds-item-checked-bg);
  color: var(--ds-item-checked-color);
}
</style>

<style scoped>
.dropdown-trigger {
  background: var(--bg-input);
  border: 1px solid var(--border-default);
  color: var(--text-primary);
  border-radius: var(--radius-md);
  padding: 0.45rem 0.8rem;
  cursor: pointer;
  font-size: 0.9rem;
  display: flex;
  align-items: center;
  gap: var(--space-2);
  outline: none;
  transition:
    border-color 0.15s ease,
    background-color 0.15s ease;
}

.dropdown-trigger .chevron {
  font-size: 0.7rem;
}

.dropdown-trigger:hover {
  background: var(--hover-tint);
  border-color: var(--border-strong);
}

.dropdown-trigger:focus-visible {
  outline: 2px solid var(--primary);
  outline-offset: 2px;
}

.dropdown-value {
  text-transform: capitalize;
}
</style>
