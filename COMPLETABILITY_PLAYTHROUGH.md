# PRUEBA DE COMPLETABILIDAD — La Cosecha del Color
**Versión**: 1.0  
**Fecha**: 2026-11-05  
**Objetivo**: Verificar que ambas rutas (buen/mal final) son alcanzables en los 4 modos de dificultad

---

## RUTA CRÍTICA DE OBJETOS (Camino Dorado)

```
manivela_pozo (casa_principal) 
  → aceite_lampara (casa_principal) 
    → campo_cultivo → laberinto (requiere aceite) 
      → bosque → laberinto (vuelta) → zapato_hijo (VISIÓN HIJO)
    → crater_meteorito → llave_oxidada 
      → establo (requiere llave) → ganado_establo (VISIÓN PADRE)
  → atico (desde casa_principal) → diario_madre (VISIÓN MADRE)
  → pozo (requiere manivela) → DECISIÓN: Descender (buen final) / Retirarse (mal final)
```

**Órden obligatorio**: 3 visiones → manivela → pozo → decisión

---

## PLAYTHROUGH POR MODO

### MODO STORY (Modo Historia)
**Configuración**: sanity_drain=0.35, time_limit=1800s (30 min), terror=0.65, enemy=0.78

| Paso | Zona | Acción | Objeto/Pista | Visión | Tiempo estimado |
|------|------|--------|--------------|--------|-----------------|
| 1 | camino_entrada | Examinar buzón | carta | - | 0:30 |
| 2 | casa_principal | Examinar fotos/radio | - | - | 1:30 |
| 3 | casa_principal | Recoger manivela_pozo | ✅ manivela_pozo | - | 2:00 |
| 4 | casa_principal | Recoger aceite_lampara | ✅ aceite_lampara | - | 2:15 |
| 5 | casa_principal → atico | Subir escalera | - | - | 2:30 |
| 6 | atico | Examinar diario_madre | ✅ diario_madre | 👁️ **MADRE** | 3:30 |
| 7 | atico → casa_principal | Bajar | - | - | 4:00 |
| 8 | casa_principal → campo_cultivo | Salida lateral | - | - | 4:15 |
| 9 | campo_cultivo → crater_meteorito | Hacia el cráter | - | - | 5:00 |
| 10 | crater_meteorito | Examinar piedra/recorte | - | - | 5:45 |
| 11 | crater_meteorito | Recoger llave_oxidada | ✅ llave_oxidada | - | 6:00 |
| 12 | crater_meteorito → camino_entrada | Vuelta | - | - | 6:30 |
| 13 | camino_entrada → casa_principal → campo_cultivo | Retorno | - | - | 7:00 |
| 14 | campo_cultivo → establo | Requiere llave_oxidada | - | - | 7:30 |
| 15 | establo | Examinar ganado_establo | ✅ (llave usada) | 👁️ **PADRE** | 8:30 |
| 16 | establo → campo_cultivo | Vuelta | - | - | 9:00 |
| 17 | campo_cultivo → laberinto | Requiere aceite_lampara | - | - | 9:15 |
| 18 | laberinto | Navegar a salida bosque | - | - | 11:00 |
| 19 | bosque | Recoger zapato_hijo | ✅ zapato_hijo | 👁️ **HIJO** | 12:00 |
| 20 | bosque → laberinto | Vuelta | - | - | 12:30 |
| 21 | laberinto → campo_cultivo | Salida dinámica | - | - | 13:00 |
| 22 | campo_cultivo → pozo | Hacia el pozo | - | - | 13:30 |
| 23 | pozo | **DECISIÓN: Descender** | manivela_pozo ✓ + 3 visiones ✓ | - | **BUEN FINAL** 14:00 |
| 23b | pozo | **DECISIÓN: Retirarse** | - | - | **MAL FINAL** 13:45 |

**Verificación STORY**:
- [ ] Buen final alcanzable < 15 min (límite 30 min)
- [ ] Mal final alcanzable en cualquier momento
- [ ] Cordura no llega a 0 en ruta óptima
- [ ] Enemigo establo patrulla lento (1.9 × 0.78 = 1.48)
- [ ] Enemigo laberinto chase_speed = 6.0 × 1.12 × 0.78 = 5.24 < run_speed 6.0

---

### MODO NORMAL (Equilibrado)
**Configuración**: sanity_drain=1.0, time_limit=900s (15 min), terror=1.0, enemy=1.0

| Paso | Zona | Acción | Objeto/Pista | Visión | Tiempo estimado |
|------|------|--------|--------------|--------|-----------------|
| 1-23 | Igual que STORY | - | - | - | **~14:30** |

**Diferencias críticas NORMAL**:
- Corrupción límite: 15 min (ruta óptima ~14:30 = **muy ajustado**)
- Enemy speed ×1.0: establo patrol=1.9, laberinto chase=6.0×1.08=6.48 > run_speed 6.0
- Sanity drain normal: correr cerca corrupción drena 8/s
- Rubber-band: close_ratio=0.92, far_ratio=1.08 (enemigo alcanza en ruta limpia)

**Verificación NORMAL**:
- [ ] Buen final alcanzable < 15 min (margen ~30 seg)
- [ ] Mal final siempre disponible
- [ ] Gestión cordura crítica: evitar correr en zonas altas corrupción
- [ ] Enemigo laberinto PUEDE alcanzar → requiere tropiezos/maze nav
- [ ] Stumble chance 35% da ventana escape

---

### MODO HARD (Difícil)
**Configuración**: sanity_drain=1.35, time_limit=720s (12 min), terror=1.3, enemy=1.12

| Paso | Zona | Acción | Objeto/Pista | Visión | Tiempo estimado |
|------|------|--------|--------------|--------|-----------------|
| 1-23 | Igual ruta | - | - | - | **~15:00** (excede límite) |

**Diferencias críticas HARD**:
- ⚠️ **Límite 12 min vs ruta óptima ~15 min = IMPOSIBLE sin atajos**
- Enemy speed ×1.12: establo patrol=2.13, laberinto chase=6.0×1.22×1.12=8.23 >> run_speed
- Sanity drain ×1.35: correr drena 10.8/s cerca corrupción
- Rubber-band: close_ratio=1.05, far_ratio=1.11 (enemigo SIEMPRE más rápido)

**Verificación HARD**:
- [ ] **BUG CONOCIDO**: Ruta dorada excede time_limit → requiere ruta alternativa o ajuste
- [ ] Posible solución: time_limit_base en HARD debería ser ≥ 900s o ruta más corta
- [ ] Mal final siempre disponible (no requiere tiempo)
- [ ] Buen final **NO alcanzable** en playthrough estándar → **BLOQUEANTE**

---

### MODO LOVECRAFT (Extremo)
**Configuración**: sanity_drain=1.8, time_limit=600s (10 min), terror=1.65, enemy=1.22

| Paso | Zona | Acción | Objeto/Pista | Visión | Tiempo estimado |
|------|------|--------|--------------|--------|-----------------|
| 1-23 | Igual ruta | - | - | - | **~15:00** (excede límite 2.5x) |

**Diferencias críticas LOVECRAFT**:
- ⚠️ **Límite 10 min vs ruta óptima ~15 min = IMPOSIBLE**
- Enemy speed ×1.22: laberinto chase=6.0×1.30×1.22=9.52 >> run_speed
- Sanity drain ×1.8: correr drena 14.4/s
- Rubber-band: close_ratio=1.05, far_ratio=1.14

**Verificación LOVECRAFT**:
- [ ] **BUG CONOCIDO**: Buen final NO alcanzable → **BLOQUEANTE**
- [ ] Mal final siempre disponible
- [ ] Diseño: "Siempre es posible sobrevivir" (descripción) pero buen final no
- [ ] Requiere: time_limit_base ≥ 900s o ruta express / atajos

---

## MATRIZ DE COMPLETABILIDAD

| Final / Modo | STORY (30m) | NORMAL (15m) | HARD (12m) | LOVECRAFT (10m) |
|--------------|:-----------:|:------------:|:----------:|:---------------:|
| **Buen final** | ✅ Alcanzable | ⚠️ Ajustado (30s) | ❌ **IMPOSIBLE** | ❌ **IMPOSIBLE** |
| **Mal final** | ✅ Siempre | ✅ Siempre | ✅ Siempre | ✅ Siempre |

---

## RUTAS ALTERNATIVAS PARA HARD/LOVECRAFT (Propuestas)

### Ruta Express (saltarse establo/cráter - solo 2 visiones)
```
casa_principal (manivela + aceite + madre) 
  → campo_cultivo → laberinto (aceite) → bosque (hijo) 
  → laberinto → campo_cultivo → pozo
```
- **Visions**: Madre + Hijo = 2/3 → **BUEN FINAL NO** (requiere 3)

### Ruta Express + Establo (saltarse cráter - pero establo requiere llave de cráter)
```
casa_principal (manivela + aceite + madre) 
  → campo_cultivo → establo (req. llave_oxidada de cráter) ← BLOQUEADO
```

### Conclusión: DISEÑO REQUERIDO
Para que HARD/LOVECRAFT tengan buen final alcanzable:
1. **Opción A**: Aumentar time_limit_base en DIFFICULTIES a 900s (15m) mínimo
2. **Opción B**: Añadir atajo (ej. llave_oxidada en casa_principal también)
3. **Opción C**: Reducir ruta crítica (hacer 2 visiones suficiente en difícil+)
4. **Opción D**: Cambiar descripción "Siempre es posible sobrevivir" → solo mal final en difícil+

**Recomendación QA**: Opción A (time_limit 900s para todos) + Opción C (2 visiones en hard/lovecraft)

---

## CHECKLIST EJECUCIÓN PLAYTHROUGH

### Por cada modo (STORY, NORMAL, HARD, LOVECRAFT):
- [ ] Nueva partida en modo X
- [ ] Completar ruta dorada completa (pasos 1-23)
- [ ] Verificar tiempo total vs corruption_time_limit
- [ ] En pozo: elegir **Descender** → confirmar EndingGood3D.tscn
- [ ] Nueva partida modo X
- [ ] Llegar a pozo (cualquier ruta)
- [ ] En pozo: elegir **Retirarse** → confirmar EndingBad3D.tscn
- [ ] Verificar guardado/carga en punto medio (ej. tras visión madre)
- [ ] Verificar FPS ≥ 30 en laberinto (peor caso)

### Métricas a registrar:
| Métrica | STORY | NORMAL | HARD | LOVECRAFT |
|---------|-------|--------|------|-----------|
| Tiempo ruta dorada | | | | |
| Tiempo a pozo (ruta corta) | | | | |
| Cordura final (ruta dorada) | | | | |
| Veces atrapado por enemigo | | | | |
| FPS medio laberinto | | | | |
| Buen final logrado | S/N | S/N | S/N | S/N |
| Mal final logrado | S/N | S/N | S/N | S/N |