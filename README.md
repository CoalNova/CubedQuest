# CubedQuest
### Rolling Cube Game

A small and lite cube rolling game where you collect coins, avoid enemies, and reach the exit. It utilizes an in-game editor for custom levels and packaging for level packs. CubedQuest (CQ<sup>3</sup>) aims to be viable on a majority of devices through reduced resource usage.

Utilizes Dependencies from [Zig-Gamedev](https://github.com/michal-z/zig-gamedev), notably ZBullet, ZSDL, ZOpenGL, and ZMath.

Code on github is missing some assets required for proper execution. This codebase exists to be an example for further engine development. 

--- 

Version Numbering is: Release.Phase.Minor[Suffix] 

Where Release is a release state, Phase relates to progress phase, Minor is plain codebase update, and Suffix is an optional letter-designation regarding additional meta on version.

|Suffix|Meaning|
|:---:|:---|
|a,b,c|small one line/file addendum|
|x|Non compiling or crashing|
|m|Mergable version, used later for git branching|
|rc|Release candidate|
|demo|Alpha/Beta demonstration|

---

Project Phasing:

- Phase 0: Project Setup
    - File Layout
    - File/Folder Structuring
    - Naming Conventions

- Phase 1: Types 
    - Simple Types
        - Multi-integer "Points"
        - Multi-floats "Floats"
        - Position
            - Dimensional Resolution
        - Euclid

    - Complex Types
        - OGDs
        - Cubes

- Phase 2: Library Integration

    - Zig-Gamedev integration
        - ZSDL integration
        - ZOpenGL integration
        - ZMath integration
        - ZPhysics (Jolt) integration

    - Direct Rendering
        - Triangle of Power
        - The Rainbow Cube (all shall praise)

    - Event Handling
        - Input states for KB+M (Down, Stay, Left, None)

- Phase 3: Level Management
    - Basic level generation
        - Level type 
        - Runtime type with parsing
    
    - Level State
        - Switching
        - State-based execution

- Phase 4: Asset Management
    - Texture Management
        - Texture Stack

    - Arbitrary Asset Management system

    - UI Management
        - Buffer updating/blitting

- Phase 5: Editing
    - FileIO
        - Level struct serialization/deserialization
        - Level files loading and unloading
        - Settings struct serialization/deserialization
        - Settings file loading and unloading

    - Edit Mode
        - Add/remove Cubes
        - Carrier
        - State Changes
        - Undo/Redo

- Phase 6: Advanced Shaders
    - Shadows
    - Point Lights
    - Directional Lights
    - Particles

- Phase7: Audio
    - Impact Noise
    - Music

- Phase 8: Customization 
    - Settings Implementation
    - Language Implementation
    - Input Rebinding
