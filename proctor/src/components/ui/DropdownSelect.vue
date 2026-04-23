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
    <SelectTrigger class="dropdown-trigger" aria-label="Select option">
      <i v-if="selectedIcon" :class="selectedIcon"></i>
      <SelectValue class="dropdown-value" :placeholder="placeholder" />
      <i class="bi bi-chevron-down chevron"></i>
    </SelectTrigger>

    <SelectPortal>
      <SelectContent class="dropdown-menu" position="popper" align="end" :side-offset="8">
        <SelectViewport class="dropdown-viewport">
          <SelectItem
            v-for="item in items"
            :key="item.value"
            class="dropdown-item"
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

<style scoped>
.dropdown-trigger {
  background: transparent;
  border: 1px solid hsla(0, 0%, 100%, 0.7);
  color: white;
  border-radius: 5px;
  padding: 0.45rem 0.8rem;
  cursor: pointer;
  font-size: 0.9rem;
  display: flex;
  align-items: center;
  gap: 0.5rem;
  outline: none;
}

.dropdown-trigger .chevron {
  font-size: 0.7rem;
}

.dropdown-trigger:hover {
  background: hsla(0, 0%, 100%, 0.15);
  border-color: #fff;
}

.dropdown-trigger:focus-visible {
  outline: 2px solid var(--primary);
  outline-offset: 2px;
}

.dropdown-value {
  text-transform: capitalize;
}

.dropdown-viewport {
  display: flex;
  flex-direction: column;
  gap: 4px;
  padding: 0;
}

.dropdown-item {
  background: transparent;
  border: none;
  color: var(--text-secondary);
  padding: 8px 12px;
  border-radius: 6px;
  cursor: pointer;
  text-align: left;
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 0.95rem;
  font-weight: 500;
  width: 100%;
  box-sizing: border-box;
}

.dropdown-item[data-highlighted] {
  background: var(--bg-input);
  color: var(--text-primary);
}

.dropdown-item:focus-visible {
  outline: 2px solid var(--primary);
  outline-offset: -2px;
}

.dropdown-item[data-state='checked'] {
  background: var(--primary);
  color: white;
}

:deep(.dropdown-menu) {
  background-color: var(--bg-body) !important;
  border: 1px solid var(--border-default);
  border-radius: 8px;
  padding: 8px;
  min-width: 160px;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.2);
  z-index: 100;
}
</style>
