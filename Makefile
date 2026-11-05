# The shared targets live in toolchain/nest.mk, which comes from the
# godot-addon-nest template. `make upgrade` refreshes it and this file. Run
# `make help` inside the dev container. Put this repo's own targets in
# local.mk, which `make upgrade` leaves alone.
include toolchain/nest.mk
-include local.mk
