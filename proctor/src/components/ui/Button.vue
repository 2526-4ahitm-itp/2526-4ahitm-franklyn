<script setup lang="ts">
import { computed, useSlots } from 'vue'

defineOptions({
  name: 'UiButton'
})

interface ButtonProps {
  variant?: 'primary' | 'secondary' | 'danger'
  size?: 'normal' | 'large'
  disabled?: boolean
  loading?: boolean
  as?: 'button' | 'a' | 'router-link'
  href?: string
  to?: string
  type?: 'button' | 'submit' | 'reset'
  icon?: string
  ariaLabel?: string
}

const props = withDefaults(defineProps<ButtonProps>(), {
  variant: 'primary',
  size: 'normal',
  disabled: false,
  loading: false,
  as: 'button',
  type: 'button',
  href: undefined,
  to: undefined,
  icon: undefined,
  ariaLabel: undefined
})

const slots = useSlots()
const hasDefaultSlot = computed(() => !!slots.default)

// Determine which component to render
const buttonComponent = computed(() => {
  if (props.as === 'router-link') {
    return 'RouterLink'
  }
  return props.as === 'a' ? 'a' : 'button'
})

// Determine actual disabled state (loading also disables)
const isDisabled = computed(() => props.disabled || props.loading)

// Determine type attribute for button elements
const buttonType = computed(() => {
  return props.as === 'button' ? props.type : undefined
})

// Generate CSS classes
const buttonClasses = computed(() => {
  return [
    'button',
    `button--${props.variant}`,
    `button--${props.size}`,
    {
      'button--disabled': isDisabled.value,
      'button--icon-only': props.icon && !hasDefaultSlot.value
    }
  ]
})
</script>

<template>
  <component
    :is="buttonComponent"
    :class="buttonClasses"
    :disabled="isDisabled"
    :href="href"
    :to="to"
    :type="buttonType"
    :aria-label="ariaLabel"
    :aria-disabled="isDisabled"
    v-bind="$attrs"
  >
    <i v-if="icon" :class="['bi', icon, { 'icon-with-text': hasDefaultSlot }]" />
    <slot v-if="hasDefaultSlot" />
  </component>
</template>

<style scoped>
.button {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  border-radius: 6px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.15s ease;
  user-select: none;
  text-decoration: none;
  border: none;
  outline: none;
}

.button:focus-visible {
  outline: 2px solid var(--primary);
  outline-offset: 2px;
}

.button--disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

/* ========== VARIANTS ========== */

/* Primary - Blue main actions */
.button--primary {
  background: var(--primary);
  color: white;
}

.button--primary:hover:not(.button--disabled) {
  opacity: 0.9;
}

/* Secondary (Ghost/Transparent) - Subtle actions */
.button--secondary {
  background: transparent;
  border: 1px solid var(--border-default);
  color: var(--text-primary);
}

.button--secondary:hover:not(.button--disabled) {
  background: var(--bg-subtle);
}

.button--secondary:active:not(.button--disabled) {
  background: var(--border-default);
}

/* Danger - Destructive actions */
.button--danger {
  background: transparent;
  border: 1px solid var(--error);
  color: var(--error);
}

.button--danger:hover:not(.button--disabled) {
  background: var(--alert-error-bg);
}

/* ========== SIZES ========== */

/* Normal */
.button--normal {
  padding: 8px 16px;
  font-size: 0.875rem;
  min-height: 36px;
}

/* Large */
.button--large {
  padding: 12px 24px;
  font-size: 1rem;
  min-height: 44px;
}

/* ========== ICONS ========== */

.icon-with-text {
  font-size: 1.1em;
}

.button--icon-only {
  padding: 8px;
  min-width: 36px;
  min-height: 36px;
}

.button--large.button--icon-only {
  padding: 12px;
  min-width: 44px;
  min-height: 44px;
}
</style>
