# AI Website Development Plan
# Universal step-by-step plan for website creation

---

## PURPOSE OF THIS DOCUMENT

This document defines a **clear development roadmap** for building a website.
It helps ensure:
- structured work
- predictable results
- high code quality
- no missed steps

Follow this plan strictly from top to bottom.

**Note:** This plan works together with `rules.md` which defines role, behavior, design principles, tech stack, and coding guidelines.

---
<!--
РУССКИЙ КОММЕНТАРИЙ:
Этот файл — не про «как писать код», а про порядок и логику работы.
-->

## GLOBAL RULES

- Work step by step
- Do not skip stages
- Do not mix stages
- Finish each stage completely before moving on
- Always think before writing code

---
<!--
РУССКИЙ КОММЕНТАРИЙ:
Важно, чтобы ИИ не перескакивал этапы.
-->

## STAGE 1 — PROJECT ANALYSIS

### Goals
- understand business objectives
- understand target audience
- define main user actions
- define success criteria

### Tasks
- review project context
- clarify website type
- identify primary CTA
- list required pages

### Output
- clear understanding of project goals
- confirmed site structure

---
<!--
РУССКИЙ КОММЕНТАРИЙ:
Этот этап формирует логику всего сайта.
-->

## STAGE 2 — INFORMATION ARCHITECTURE

### Goals
- define page hierarchy
- define navigation structure
- define content blocks

### Tasks
- create sitemap
- define section order
- decide what content goes where

### Output
- logical page structure
- clear navigation map

---
<!--
РУССКИЙ КОММЕНТАРИЙ:
Без этого этапа сайт будет «разрозненным».
-->

## STAGE 3 — WIREFRAMES (LOGIC FIRST)

### Goals
- focus on structure, not design
- ensure usability and clarity

### Tasks
- outline page layouts
- define block hierarchy
- define CTA placement

### Rules
- no colors
- no images
- no animations

### Output
- clear wireframe logic for each page

---
<!--
РУССКИЙ КОММЕНТАРИЙ:
Если wireframe слабый — дизайн не спасёт.
-->

## STAGE 4 — CONTENT PREPARATION

### Goals
- prepare meaningful content
- avoid placeholders

### Tasks
- write headlines
- write body text
- define CTA texts
- prepare lists and descriptions

### Rules
- content before design
- clarity over creativity

### Output
- final or near-final text content

---
<!--
РУССКИЙ КОММЕНТАРИЙ:
Очень важно — сначала смысл, потом визуал.
-->

## STAGE 5 — HTML STRUCTURE

### Goals
- build semantic foundation
- prepare for styling
- establish SEO foundation

### Tasks
- create HTML files
- use semantic tags
- structure content correctly
- add basic meta tags (title, description, charset, viewport)
- ensure proper heading hierarchy (H1, H2, H3)

### Rules
- no inline styles
- no JavaScript
- focus on semantics
- SEO-ready structure

### Output
- clean semantic HTML structure
- basic SEO foundation (meta tags, semantic structure)

---
<!--
РУССКИЙ КОММЕНТАРИЙ:
Это фундамент всего проекта.
-->

## STAGE 6 — BASE CSS

### Goals
- establish visual system
- ensure readability

### Tasks
- define CSS variables
- set typography
- set spacing system
- basic layout (Grid / Flexbox)

### Rules
- mobile later, desktop first
- no detailed styling yet

### Output
- readable, structured layout

---
<!--
РУССКИЙ КОММЕНТАРИЙ:
На этом этапе сайт уже должен «читаться».
-->

## STAGE 7 — DETAILED STYLING

### Goals
- finalize visual appearance
- improve clarity and hierarchy

### Tasks
- refine sections
- style buttons and CTAs
- improve spacing and contrast
- add simple transitions

### Rules
- design serves content
- avoid over-decoration

### Output
- finished visual design

---
<!--
РУССКИЙ КОММЕНТАРИЙ:
Здесь появляется «чистый продающий дизайн».
-->

## STAGE 8 — RESPONSIVENESS

### Goals
- ensure usability on all devices
- adapt desktop design for smaller screens

### Tasks
- adapt layouts for tablet (from desktop version)
- adapt layouts for mobile (from desktop version)
- adjust typography and spacing for smaller screens
- test breakpoints and ensure content remains accessible

### Rules
- no content removal
- preserve hierarchy
- desktop-first approach: adapt desktop design, don't rebuild

### Output
- fully responsive website (desktop → tablet → mobile)

---
<!--
РУССКИЙ КОММЕНТАРИЙ:
Адаптация — обязательна, даже для B2B.
-->

## STAGE 9 — JAVASCRIPT ENHANCEMENTS

### Goals
- add necessary interactivity

### Allowed tasks
- smooth scrolling
- form validation
- modal windows
- small UX improvements

### Rules
- minimal JS
- progressive enhancement
- site must work without JS

### Output
- stable, unobtrusive interactivity

---
<!--
РУССКИЙ КОММЕНТАРИЙ:
JS — усиление, а не основа.
-->

## STAGE 10 — TESTING & QA

### Goals
- ensure stability
- catch errors

### Tasks
- test in modern browsers
- check responsiveness
- validate forms
- review accessibility basics

### Output
- bug-free version

---
<!--
РУССКИЙ КОММЕНТАРИЙ:
Даже ИИ должен «проверять себя».
-->

## STAGE 11 — SEO & OPTIMIZATION

### Goals
- improve maintainability
- optimize for search engines
- optimize performance
- prepare for handoff

### Tasks
- add complete SEO elements (meta tags, Schema.org markup, Open Graph)
- optimize images (formats, lazy-load, alt attributes)
- optimize performance (critical CSS, minification, LCP < 2.5s, CLS < 0.1)
- remove unused code
- organize files
- add comments where needed

### Rules
- SEO must be complete (meta tags, Schema.org, semantic HTML)
- Performance targets must be met
- All images must have alt attributes

### Output
- SEO-optimized website
- performance-optimized codebase
- clean production-ready code

---
<!--
РУССКИЙ КОММЕНТАРИЙ:
Этот этап часто пропускают — не надо.
-->

## STAGE 12 — FINAL DELIVERY

### Goals
- deliver complete product
- ensure all requirements are met

### Tasks
- final review of all pages
- ensure consistency across site
- verify all functionality works
- check SEO and performance metrics
- prepare for deployment on fichart.ru

### Output
- fully ready website
- SEO-optimized
- performance-optimized
- easy to extend
- safe to deploy

---
<!--
РУССКИЙ КОММЕНТАРИЙ:
Финал — сайт должен быть реально готов.
-->

## DEVELOPMENT PHILOSOPHY

- Structure before style
- Content before visuals
- Simplicity over complexity
- Clarity over creativity

Act like a senior developer working on a real client project.

