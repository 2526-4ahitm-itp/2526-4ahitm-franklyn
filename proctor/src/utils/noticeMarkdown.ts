import DOMPurify from 'dompurify'
import MarkdownIt from 'markdown-it'

const markdown = new MarkdownIt({
  html: false,
  linkify: true,
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

markdown.renderer.rules.link_open = (tokens, index, options, _env, self) => {
  const token = tokens[index]
  token.attrSet('target', '_blank')
  token.attrSet('rel', 'noopener noreferrer')
  return self.renderToken(tokens, index, options)
}

const allowedTags = ['a', 'code', 'em', 's', 'strong']
const allowedAttributes = { a: ['href', 'rel', 'target'] }

export function renderNoticeMarkdown(value: string): string {
  const source = value.trim()
  if (!source) return ''

  const rendered = markdown.renderInline(source)

  return DOMPurify.sanitize(rendered, {
    ALLOWED_TAGS: allowedTags,
    ALLOWED_ATTR: allowedAttributes,
    ADD_ATTR: ['rel', 'target'],
    FORCE_BODY: false,
  })
}
