# Package

version       = "0.1.0"
author        = "Willi Schinmeyer"
description   = "A character build assistant for Destiny 2"
license       = "MIT"
srcDir        = "src"
bin           = @["destiny_builder"]


# Dependencies

requires "nim >= 0.19.0", "karax >= 0.2.0"

# Additional Tasks

#task frontend, "builds the Frontend"