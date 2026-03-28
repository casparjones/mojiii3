#!/usr/bin/env bash
set -euo pipefail

# Load FAL_KEY from .env
export $(cat /work/work-data/projects/match3/.env | xargs)

OUT_DIR="/work/work-data/projects/match3/assets/backgrounds"
mkdir -p "$OUT_DIR"

generate() {
  local name="$1"
  local prompt="$2"
  local width="$3"
  local height="$4"
  local outfile="$OUT_DIR/${name}.png"

  if [[ -f "$outfile" ]]; then
    echo "SKIP $name (exists)"
    return
  fi

  echo "GEN  $name (${width}x${height})..."

  local response
  response=$(curl -s -X POST "https://fal.run/fal-ai/flux/dev" \
    -H "Authorization: Key $FAL_KEY" \
    -H "Content-Type: application/json" \
    -d "{
      \"prompt\": \"$prompt\",
      \"image_size\": {\"width\": $width, \"height\": $height},
      \"num_images\": 1,
      \"num_inference_steps\": 28
    }")

  local url
  url=$(echo "$response" | python3 -c "import sys,json; print(json.load(sys.stdin)['images'][0]['url'])" 2>/dev/null)

  if [[ -n "$url" && "$url" != "None" ]]; then
    curl -s -o "$outfile" "$url"
    echo "DONE $name"
  else
    echo "FAIL $name: $response"
  fi
}

STYLE="soft painted illustration style, pastel colors, dreamy atmosphere, gentle gradients, no text, no UI elements, suitable as a game background with space for UI overlay, slightly blurred depth of field"

# Level 1-10: Friendly animals, nature
generate "level_01_10_portrait" \
  "Friendly cute woodland animals (deer, rabbits, birds, squirrels) in a gentle meadow with wildflowers, soft sunlight through trees, painted watercolor style, warm colors, portrait composition, $STYLE" \
  1080 1920

generate "level_01_10_landscape" \
  "Friendly cute woodland animals (deer, rabbits, birds, squirrels) in a gentle meadow with wildflowers, soft sunlight through trees, painted watercolor style, warm colors, landscape wide composition, $STYLE" \
  1920 1080

# Level 11-20: Beach & ocean
generate "level_11_20_portrait" \
  "Tropical beach scene with turquoise ocean, white sand, palm trees, playful dolphins and colorful fish jumping, coral visible in shallow water, golden sunset, portrait composition, $STYLE" \
  1080 1920

generate "level_11_20_landscape" \
  "Tropical beach scene with turquoise ocean, white sand, palm trees, playful dolphins and colorful fish jumping, coral visible in shallow water, golden sunset, landscape wide composition, $STYLE" \
  1920 1080

# Level 21-30: Enchanted forest
generate "level_21_30_portrait" \
  "Enchanted magical forest with giant glowing mushrooms, fireflies, bioluminescent plants, mystical fog, ancient twisted trees with fairy lights, purple and teal color palette, portrait composition, $STYLE" \
  1080 1920

generate "level_21_30_landscape" \
  "Enchanted magical forest with giant glowing mushrooms, fireflies, bioluminescent plants, mystical fog, ancient twisted trees with fairy lights, purple and teal color palette, landscape wide composition, $STYLE" \
  1920 1080

# Level 31-40: Snow & aurora
generate "level_31_40_portrait" \
  "Snowy mountain landscape with northern lights aurora borealis in green and purple, frozen lake, snow-covered pine trees, starry night sky, peaceful winter scene, portrait composition, $STYLE" \
  1080 1920

generate "level_31_40_landscape" \
  "Snowy mountain landscape with northern lights aurora borealis in green and purple, frozen lake, snow-covered pine trees, starry night sky, peaceful winter scene, landscape wide composition, $STYLE" \
  1920 1080

# Level 41-50: Desert oasis
generate "level_41_50_portrait" \
  "Desert oasis with golden sand dunes, ancient pyramids in the distance, lush palm oasis with clear pool, camels, warm orange and gold sunset sky, exotic birds, portrait composition, $STYLE" \
  1080 1920

generate "level_41_50_landscape" \
  "Desert oasis with golden sand dunes, ancient pyramids in the distance, lush palm oasis with clear pool, camels, warm orange and gold sunset sky, exotic birds, landscape wide composition, $STYLE" \
  1920 1080

# Level 51-60: Candy land
generate "level_51_60_portrait" \
  "Whimsical candy land with lollipop trees, chocolate rivers, gummy bear mountains, cotton candy clouds, rainbow bridges, colorful sweets landscape, bright and cheerful, portrait composition, $STYLE" \
  1080 1920

generate "level_51_60_landscape" \
  "Whimsical candy land with lollipop trees, chocolate rivers, gummy bear mountains, cotton candy clouds, rainbow bridges, colorful sweets landscape, bright and cheerful, landscape wide composition, $STYLE" \
  1920 1080

# Level 61-70: Space & galaxies
generate "level_61_70_portrait" \
  "Deep space scene with colorful nebula, distant galaxies, glowing planets with rings, asteroid field, shooting stars, cosmic dust clouds in purple blue and pink, portrait composition, $STYLE" \
  1080 1920

generate "level_61_70_landscape" \
  "Deep space scene with colorful nebula, distant galaxies, glowing planets with rings, asteroid field, shooting stars, cosmic dust clouds in purple blue and pink, landscape wide composition, $STYLE" \
  1920 1080

# Level 71-80: Deep sea coral reef
generate "level_71_80_portrait" \
  "Deep underwater coral reef with vibrant corals, tropical fish schools, sea turtles, jellyfish with bioluminescence, sunlight rays filtering through water, blues and teals, portrait composition, $STYLE" \
  1080 1920

generate "level_71_80_landscape" \
  "Deep underwater coral reef with vibrant corals, tropical fish schools, sea turtles, jellyfish with bioluminescence, sunlight rays filtering through water, blues and teals, landscape wide composition, $STYLE" \
  1920 1080

# Level 81-90: Volcanic island
generate "level_81_90_portrait" \
  "Dramatic volcanic island with glowing lava flows, fiery eruption, tropical vegetation, obsidian rocks, orange and red sky, magma pools, dramatic atmosphere, portrait composition, $STYLE" \
  1080 1920

generate "level_81_90_landscape" \
  "Dramatic volcanic island with glowing lava flows, fiery eruption, tropical vegetation, obsidian rocks, orange and red sky, magma pools, dramatic atmosphere, landscape wide composition, $STYLE" \
  1920 1080

# Level 91-100: Crystal cave
generate "level_91_100_portrait" \
  "Magical crystal cave with giant amethyst and quartz formations, rainbow light refractions, underground lake, glowing crystals in purple pink and blue, mystical energy, portrait composition, $STYLE" \
  1080 1920

generate "level_91_100_landscape" \
  "Magical crystal cave with giant amethyst and quartz formations, rainbow light refractions, underground lake, glowing crystals in purple pink and blue, mystical energy, landscape wide composition, $STYLE" \
  1920 1080

echo ""
echo "=== All done! ==="
ls -la "$OUT_DIR"/*.png 2>/dev/null | wc -l
echo "images generated in $OUT_DIR"
