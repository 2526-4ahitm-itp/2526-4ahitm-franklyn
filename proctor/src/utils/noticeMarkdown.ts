import MarkdownIt from 'markdown-it'
import type { Config } from 'dompurify'

const markdown = new MarkdownIt({
  html: false,
  linkify: false,
  breaks: false,
})

markdown.disable([
  'blockquote',
  'code',
  'fence',
  'heading',
  'hr',
  'image',
  'list',
  'paragraph',
  'table',
])

markdown.enable(['emphasis', 'strikethrough', 'link', 'backticks'])

const defaultLinkOpen = markdown.renderer.rules.link_open

markdown.renderer.rules.link_open = (tokens, index, options, env, self) => {
  const token = tokens[index]
  if (token) {
    token.attrSet('target', '_blank')
    token.attrSet('rel', 'noopener noreferrer')
  }

  if (defaultLinkOpen) {
    return defaultLinkOpen(tokens, index, options, env, self)
  }

  return self.renderToken(tokens, index, options)
}

export const noticeSanitizeConfig: Config = {
  ALLOWED_TAGS: ['a', 'code', 'em', 's', 'strong'],
  ALLOWED_ATTR: ['href', 'rel', 'target'],
  ADD_ATTR: ['rel', 'target'],
  FORCE_BODY: false,
}

export function renderNoticeMarkdown(value: string): string {
  const source = value.trim()
  if (!source) return ''

  return markdown.renderInline(source)
}
