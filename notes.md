Screen space lighting shader
Instance level meshes


States:
- Currently Track states in a boolean fasion
- Adding a previous state is cheap (only another byte on the player struct) enabling:
    - Detect when first clinging to a wall
    -
rl.GetWorldToScreen(position, world.camera) - {420,648} gives a 0-ScreenHeight/Width dimensions vector, probably worth knowing for the new lighting shader
