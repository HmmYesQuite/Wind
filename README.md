Submission for Terra Hackathon.
This is the most recent version of the Wind Demo: https://hmmquite.itch.io/wind-demo-terra

Controls:

WASD for movement

E to interact with certain objects

Tab to open and close inventory

1 through 9 to select an inventory slot; using the scroll wheel works as well.

Left mouse button to use an item in your inventory (the only working one is the fishing rod)

To fish, use Left mouse button to pull the line in, and Right mouse button to lower the line.

Esc will open the pause menu

Pressing F1 will show the wind Perlin noise

Pressing F2 will put the player in noclip+flight mode.



Most recent devlog summary:

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


How to run:
Play in browser at: https://hmmquite.itch.io/wind-demo-terra
From source:
Use Godot 4.5.1
Clone the repo
Import the project.godot


Credits:

Pixel font: https://managore.itch.io/m3x6

Fruit sprite sheet: https://melancholyg.itch.io/16x16-pixel-art-food-sprites​
