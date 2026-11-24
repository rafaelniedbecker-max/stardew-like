# Stardew-Like Design System

> **Brief:** Um farming sim inspirado em Stardew Valley, com tema próprio, escopo menor, feito para diversão pessoal. Precisa de UI clara, legível, que desapareça durante o gameplay e apareça quando necessário.

---

## 1. Color System (4–6 core tokens)

Baseado na estética **rural aconchegante / pixel art / 16-bit era** — tons terrosos, vegetação, madeira, céu.

| Token | Hex | Uso | Light Mode | Dark Mode |
|-------|-----|-----|------------|-----------|
| `--surface` | `#FDF8F0` | Background principal (papel envelhecido) | `#FDF8F0` | `#1A1612` |
| `--surface-elevated` | `#F5ECD8` | Cards, painéis, menus | `#F5ECD8` | `#241E18` |
| `--surface-hover` | `#E8DCC8` | Hover em botões/cards | `#E8DCC8` | `#2E261E` |
| `--ink` | `#3D2E1F` | Texto principal (marrom escuro) | `#3D2E1F` | `#F0E8DC` |
| `--ink-muted` | `#8B7A63` | Labels, placeholders, texto secundário | `#8B7A63` | `#9D8E7A` |
| `--brand` | `#C47A3C` | Ação principal, highlights (terracota queimado) | `#C47A3C` | `#D98B4A` |
| `--brand-hover` | `#A86530` | Hover em ações principais | `#A86530` | `#C47A3C` |
| `--success` | `#5D8A4E` | Colheita, ganho, pronto | `#5D8A4E` | `#6EBF5F` |
| `--warning` | `#C49A3C` | Energia baixa, tempo acabando | `#C49A3C` | `#D9A84A` |
| `--danger` | `#A84A3C` | Vida baixa, perigo, erro | `#A84A3C` | `#C45A4A` |
| `--info` | `#4A7C9E` | Dicas, missões, água | `#4A7C9E` | `#5A9BD8` |

**Seasonal accent tokens** (mudam conforme estação):
```css
/* Spring */ --season: #A8D47A; --season-muted: #C8E8A0;
/* Summer */ --season: #F4C430; --season-muted: #F8D870;
/* Fall  */ --season: #D47A2A; --season-muted: #E8A060;
/* Winter*/ --season: #7AC8E8; --season-muted: #A0D8F0;
```

---

## 2. Typography

**Uma família principal** para tudo — legível em pixel art, boa em 12px–24px.

| Role | Font | Size | Weight | Line Height | Letter Spacing |
|------|------|------|--------|-------------|----------------|
| Display/Title | `Minecraft` / `Press Start 2P` / `Pixelify Sans` | 24–32px | Bold | 1.2 | 0.5px |
| Heading | `Pixelify Sans` / `Minecraft` | 18–22px | Medium | 1.3 | 0.3px |
| Body | `Pixelify Sans` / `Nunito Sans` / `Inter` | 14–16px | Regular | 1.5 | 0 |
| Small/Label | `Pixelify Sans` / `Nunito Sans` | 11–12px | Regular | 1.4 | 0.2px |
| Mono/Data | `JetBrains Mono` / `Fira Code` | 12–14px | Regular | 1.4 | 0 |

**Fallback stack:**
```css
font-family: 'Pixelify Sans', 'Press Start 2P', 'Minecraft', 'Nunito Sans', system-ui, sans-serif;
font-family-mono: 'JetBrains Mono', 'Fira Code', 'Consolas', monospace;
```

**Type Scale (ratio 1.25):**
```
Display:     32px / 1.2
H1:          24px / 1.3
H2:          20px / 1.3
H3:          18px / 1.4
Body:        16px / 1.5
Body-sm:     14px / 1.5
Label:       12px / 1.4
Caption:     11px / 1.4
```

---

## 3. Layout System

### Grid & Spacing
- **Base unit:** 8px (alinha com pixel art 16×16 e 32×32)
- **Spacing scale:** 4, 8, 12, 16, 24, 32, 48, 64
- **Container max-width:** 1280px (game resolution)
- **Content padding:** 16px (mobile), 24px (desktop)

### Alignment
- **Menus/painéis:** Center-aligned (contexto de jogo, leitura rápida)
- **HUD/Stats:** Left-aligned (scan rápido, comparação)
- **Diálogos:** Left-aligned, max 60ch por linha
- **Formulários:** Left-aligned labels, inputs full-width

### ASCII Wireframes

#### HUD (Top Bar)
```
┌─────────────────────────────────────────────────────────────┐
│ ☀ Spring 1, Year 1          12:00 PM    ☀️      12,500g    │
│ ████████████████████░░░░░░░  270/270     ❤️❤️❤️❤️❤️  100/100 │
├─────────────────────────────────────────────────────────────┤
│                    GAMEPLAY AREA                              │
├─────────────────────────────────────────────────────────────┤
│ [🌱] [⛏] [🪓] [💧] [🌾] [🥔] [🥕] [🌽] [  ] [  ] [  ] [  ]  │
│  1    2    3    4    5    6    7    8    9    0    -    =   │
└─────────────────────────────────────────────────────────────┘
```

#### Menu Principal (Pause/Settings)
```
┌────────────────────────────┐
│        ⏸ PAUSADO           │
│  ┌──────────────────────┐  │
│  │ ▶ Continuar          │  │
│  │ 💾 Salvar Jogo       │  │
│  │ 📂 Carregar Jogo     │  │
│  │ ⚙ Configurações      │  │
│  │ 🚪 Sair para Menu    │  │
│  └──────────────────────┘  │
│         v0.1.0             │
└────────────────────────────┘
```

#### Inventory / Crafting Grid
```
┌────────────────────────────────────────┐
│ 🎒 Inventário                    12,500g│
├────────────────────────────────────────┤
│ [🌱]x15 [🥔]x10 [🥕]x5 [⛏] [🪓] [💧]  │
│ [🌾]x20 [🍅]x8  [🌽]x12 [🐟]x3 [💎]x1  │
│ [🪵]x99 [🪨]x50 [🍄]x7  [🌿]x12 [  ]   │
├────────────────────────────────────────┤
│ [🌱] [⛏] [🪓] [💧] [🌾] [🥔] [🥕] [🌽] │
│  1    2    3    4    5    6    7    8  │
└────────────────────────────────────────┘
```

#### Dialogue Box
```
┌────────────────────────────────────────┐
│ Abigail                    💚💚💚🤍🤍      │
├────────────────────────────────────────┤
│ Ei! Quer vir no meu quarto jogar?      │
│ Tenho um jogo novo que acho que        │
│ você vai gostar...                     │
├────────────────────────────────────────┤
│ [Claro! Adoraria.]   [Talvez depois.]  │
└────────────────────────────────────────┘
```

---

## 4. Component Specs

### Button
```gdscript
# Variants
Primary:    bg=brand, color=surface, hover=brand-hover, focus:ring(brand, 2px)
Secondary:  bg=surface-elevated, color=ink, hover=surface-hover, border(1px, ink-muted)
Ghost:      bg=transparent, color=ink, hover=surface-hover
Danger:     bg=danger, color=surface, hover=darken(danger, 10%)

# Sizes
Small:  padding: 6px 12px, font: Label(12px), height: 32px
Medium: padding: 10px 20px, font: Body(14px), height: 40px
Large:  padding: 14px 28px, font: H3(18px), height: 48px

# States
:focus-visible → ring(2px, brand, 2px offset)
:disabled → opacity(0.5), cursor(not-allowed)
:active → scale(0.98)
```

### Panel / Card
```gdscript
bg: surface-elevated
border: 1px solid rgba(ink, 0.1)
radius: 8px (cards), 12px (modals)
shadow: 0 4px 16px rgba(0,0,0,0.08) / dark: 0 4px 24px rgba(0,0,0,0.3)
padding: 16px (cards), 24px (modals)
```

### Progress Bar
```gdscript
height: 8px (thin), 16px (medium), 24px (large)
radius: 4px / 8px / 12px
bg: surface
fill: brand (default), success (harvest), warning (energy), danger (health)
transition: width 0.3s ease-out
```

### Input / Select
```gdscript
height: 40px
padding: 8px 12px
bg: surface
border: 1px solid ink-muted
radius: 6px
color: ink
placeholder: ink-muted
focus: border(brand, 2px), ring(brand, 2px)
error: border(danger), ring(danger, 2px)
```

### Tooltip
```gdscript
bg: ink (90%)
color: surface
radius: 6px
padding: 8px 12px
font: Small(12px)
max-width: 280px
arrow: 6px
delay: 300ms show / 100ms hide
position: top-center (default), auto-flip
```

### Notification / Toast
```gdscript
position: top-right (stacked, gap 8px)
min-width: 280px, max-width: 400px
padding: 12px 16px
radius: 8px
icon: 20px (emoji or icon)
duration: 4s (default), 8s (long), persistent (actions)
animation: slide-in-right 0.3s ease-out / fade-out 0.3s
```

---

## 5. Icon System

**Pixel art 16×16 / 24×24** — estilo consistente, outline 1px

| Category | Examples | Style |
|----------|----------|-------|
| Tools | 🌱⛏🪓💧🌾✂️🥛⚒️ | Pixel, 1px outline, cor brand |
| Crops | 🌱🥔🥕🌽🍅🍓🌻🎃 | Pixel, cor sazonal |
| Animals | 🐔🐄🐑🐐🐷🐟 | Pixel, cor natural |
| UI | ❤️⚡💰⭐🕐📦🏠🗺️ | Emoji nativo + pixel fallback |
| Skills | 🌾⛏️🌲🎣⚔️ | Pixel, cor por skill |

---

## 6. Motion & Interaction

### Timing
| Action | Duration | Easing |
|--------|----------|--------|
| Panel open/close | 200ms | ease-out / ease-in |
| Button press | 80ms | ease-out |
| Tooltip show/hide | 200ms / 150ms | ease-out |
| Toast slide | 300ms | ease-out |
| Tab switch | 150ms | ease-out |
| Progress bar | 300ms | ease-out |
| Level up popup | 500ms | ease-out-back |

### Reduced Motion
```gdscript
# Respeita prefers-reduced-motion
# Desliga: panel animations, toast slide, progress bar animation, particle bursts
# Mantém: instant state changes, color changes, text updates
```

---

## 6. Accessibility

- **Contraste:** AA mínimo (4.5:1) em todos os textos, AAA (7:1) em headlines
- **Focus visível:** Ring 2px brand + offset 2px em todos os interativos
- **Escala de texto:** Suporta zoom 150% sem quebrar layout
- **Colorblind:** Paleta validada (CVD Delta E ≥ 8), ícones + labels sempre
- **Teclado:** Tab order lógico, Escape fecha modais, Enter/space ativa botões
- **Screen reader:** ARIA labels em ícones-only, live regions para toasts/notificações

---

## 7. Implementation Checklist

- [ ] Criar `theme.tres` Godot com todos os tokens
- [ ] Criar `UIStyle.gd` autoload com helpers (`style_button()`, `style_panel()`, etc.)
- [ ] Aplicar em todos os menus existentes (Pause, Settings, Inventory, Crafting, Cooking, TV, Collections, SpecialOrders, HeartEvents, MineTransitions, Dialogue, ShippingBin)
- [ ] Criar componentes reutilizáveis: `SDButton`, `SDPanel`, `SDProgressBar`, `SDTooltip`, `SDToast`, `SDDialogueBox`, `SDItemSlot`, `SDGridContainer`
- [ ] Validar contraste com ferramenta (axe-core, WAVE)
- [ ] Testar em 1280×720, 1920×1080, mobile (simulado)
- [ ] Documentar uso no README do projeto