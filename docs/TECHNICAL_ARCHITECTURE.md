# Technical Architecture

## Initial engine

Use a stable Godot 4.x release. Keep the project on one chosen engine version and record it in the project README once selected.

## Proposed project layout

```
zayron-simulator/
├── project.godot
├── README.md
├── docs/
│   ├── DEVELOPMENT_ROADMAP.md
│   └── TECHNICAL_ARCHITECTURE.md
├── scenes/
│   ├── main/
│   ├── vehicles/
│   ├── maps/
│   └── ui/
├── scripts/
│   ├── vehicles/
│   ├── input/
│   ├── missions/
│   └── systems/
├── assets/
│   ├── vehicles/
│   ├── environment/
│   ├── audio/
│   └── ui/
└── tests/
```

## Core systems

1. **Vehicle controller:** acceleration, braking, steering, reverse, gears, traction, and suspension.
2. **Camera:** third-person chase camera with adjustable distance and smoothing.
3. **Input abstraction:** keyboard/gamepad for development and touch UI for Android.
4. **World streaming:** load map areas in sections as the world grows.
5. **Mission system:** data-driven routes, deliveries, passengers, and rewards.
6. **Save system:** settings and player progress, added after the prototype is stable.

## Mobile performance principles

- Start with one vehicle and a small test environment.
- Use level-of-detail meshes and sensible texture sizes.
- Limit real-time lights, shadows, transparent materials, and expensive effects.
- Profile on real Android hardware; editor performance is not a reliable mobile benchmark.
- Provide scalable graphics presets rather than forcing maximum settings on every device.

## Testing strategy

- Open the project from a clean checkout.
- Run the prototype in the Godot editor.
- Test input, vehicle motion, camera, and scene transitions.
- Export and install an Android build on a real device.
- Record device model, Android version, engine version, errors, and performance observations for each test.
