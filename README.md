Submission for Terra Hackathon.
This is the most recent version of the Wind Demo: https://hmmquite.itch.io/wind-demo-terra

Controls:

WASD for movement

E to interact with certain objects

Tab to open and close inventory

1 through 9 to select an inventory slot; using the scroll wheel works as well.

Left mouse button to use an item in your inventory. Fishing rod, blocks, workbenches, axes, etc.

To fish, use Left mouse button to pull the line in, and Right mouse button to lower the line.

To build, hold the item and use Left mouse button. You can only place things near you and that are connected to another block. For the workbench, you can only put it on two empty blocks.

To break, hold down the left mouse button on a block or object that you put down; after a second, you will pick it up.

Esc will open the pause menu

Pressing F1 will show the wind Perlin noise

Pressing F2 will put the player in noclip+flight mode.

Pressing F3 will skip ahead a bit in the day.



Right now there is a bunch of test items for the sake of the demo; in the full game you will only start with the fishing rod.



Most recent devlog summary:

WEEK 3:

Changes:

Building - Craft workbenches and wood platforms, and hold them to place them on the ship you are standing on. If it turns red, then you can't place it. It's ranged.

Breaking - Holding the axe lets you break things that you placed down, like the planks or the workbench. It gives you the item back. You have to hold down the left mouse button for it to start breaking.

Saving - A very hardcoded save system; it has an auto-save that triggers on things that you change in the world, like placing, using, moving, etc. It stores it in a JSON file and remembers your progress even if you reload the tab, which I think is pretty neat. I am for sure gonna have to make some big changes to it because I have to manually add a new category every time I want to add something new.

Day Night - 300-second day-night cycle. It cycles through a gradient and tints everything on screen. Pressing F3 skips ahead a bit.

Lanterns - Have a point light now so they look better + new texture.



WEEK 2:

Added a working inventory system. Pressing Tab will open it.

There are two tabs: Crafting and Storage.

In the crafting menu, you can choose a recipe to craft (only 1 right now)

In the storage menu, you can choose one of the storage containers by hovering over the player's pockets (will improve visuals next week). These pockets have 4 slots each; you can pick up and drag items from one pocket to another, or to the hotbar. Items will automatically fill in their respective stack and will default to the hotbar.

The debris in the clouds now does something. If you collect enough, you can craft a fishing rod (pointless now because you already start with one). These materials include things like sticks, rocks, and string.

My attempt at this week's theme: Antique.

I added a "unique" item type. Uniques can randomly and rarely spawn in the cloud layer below; there can only be 1 on screen at all times. Once you collect one of these uniques, you can never catch it again.

The two uniques in the game right now are a pocket watch and a rare coin. Neither has any uses but looks cool. I plan on expanding this system.

The player now has proper textures and animations! I used Aseprite to make them, but importing them into Godot was giving me some grief. I had Claude make a quick script for importing them.

There are two animations: idle and walking.

When the player flips directions (walking left, walking right), they now have a smooth flipping animation. It's a little intense when you move your mouse across the screen a lot, but I think it's better than it just teleporting.



WEEK 1:

This update was mainly focused on simple gameplay systems, for example:

Fishing, debris floating in the cloud layer, inventory, holding items, QoL, and more.

The main addition was the fishing mechanic. Right now, holding out your fishing rod and clicking will toss out your line; holding right-click will begin to lower it down. Once you reach the cloud layer below, items will start drifting across the screen. Once you hook one of these items, you can pull it back up to the player using left-click. You will then pick up the item, and it will appear in your inventory.

Items can stack if they allow it, such as apples and pears.



Credits:

Pixel font: https://managore.itch.io/m3x6

Fruit sprite sheet: https://melancholyg.itch.io/16x16-pixel-art-food-sprites​
