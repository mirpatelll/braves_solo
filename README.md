# Braves App - CPSC 4150

## What it does
This is a Braves-themed app I built in Flutter. It has three screens. The first screen is just a welcome page with the Braves logo. The second screen shows some basic team info like the stadium and World Series titles. The third screen is where you can type in two batting averages and compare them to see which player is better. You can also tap on empty parts of the screen to change the background color.

## How to run it
Clone the repo, run flutter pub get, then flutter run and pick your simulator.

## Colors and contrast
I used 5 Braves-themed colors for the background cycling: red, navy , gold , white , and dark charcoal . I used computeLuminance() to check if the background is light or dark and then switch the text to black or white so you can always read it.

## Test inputs
- 0.325 vs 0.280 gives Player 1 winning by 0.045
- 0.300 vs 0.300 gives a tie
- leaving a field empty gives an error saying to enter a batting average
- typing something like -0.5 gives an error saying it has to be between 0 and 1
- typing letters instead of numbers gives an error saying it has to be a number