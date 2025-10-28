## Arbitrary Map sizes
### What problem does this solve
Design:
    - Add more variance, could lead to more fun immergent play
    - Less constraned design
Technical:
    - Easier to test
    - Can still store the data in one place with something like a `Map_Config` struct
LOE:
    - Some search and replace stuff
    - Good opp to clean up some of the map globals
    - still use the same
