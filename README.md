# 🔥 Datamosh - The Glitchy Video Toy™

![It Works On My Machine](https://img.shields.io/badge/It_Works-On_My_Machine-success?style=for-the-badge)
![NOT For Production](https://img.shields.io/badge/NOT_For-Production-red?style=for-the-badge)
![Glitch Level](https://img.shields.io/badge/Glitch_Level-Over_9000-blueviolet?style=for-the-badge)

A command-line tool for creating **datamosh** effects between video files, because who needs coherent frames anyway?

## What the heck is this?

This is a bash script that deliberately corrupts video files to create that oh-so-trendy glitch aesthetic where colors bleed, shapes distort, and pixels have identity crises. Some call it "datamoshing," others call it "compression artifact art".

**Important note**: This is a toy. Like that plastic hammer that squeaks when you hit things. It's for entertainment, experimentation, and making videos that look like they were transmitted from a dimension where the laws of physics are more like vague suggestions.

## Works On My Machine™ Guarantee

This software is provided with the industry-standard "Works On My Machine™" guarantee. This means I ran it on my computer one time (possibly while Mercury was in retrograde) and it didn't immediately set anything on fire. Your mileage may vary.

If it works for you - fantastic! 🎉  
If it doesn't - well, that's part of the glitch aesthetic, isn't it? 🤷‍♂️

## Installation

Believe it or not, this masterpiece has dependencies:

- `ffmpeg` (for video manipulation)
- `bc` (for math, because apparently computers need help with that)
- A sense of adventure (not available via apt-get)

```bash
# Install dependencies
sudo apt-get install ffmpeg bc

# Clone this repository
git clone https://github.com/qbixxx/datamosh.git

# Navigate to the directory
cd datamosh

# Make the script executable
chmod +x datamosh.sh

# Question your life choices
echo "What am I doing with my time?"
```

## Usage

Basic usage is straightforward, assuming you define "straightforward" as "borderline destructive manipulation of binary data":

```bash
./datamosh.sh input1.mp4 input2.mp4
```

This will create a datamoshed video with a timestamped filename like `datamoshed_20250501_123045.mp4`, because naming things is hard and timestamps solve everything.

### Advanced Usage (for the brave)

```bash
# Specify an output filename (we'll add a timestamp anyway because trust issues)
./datamosh.sh input1.mp4 input2.mp4 my_glitchy_creation.mp4

# Apply a profile for different glitch effects
./datamosh.sh --profile bloom input1.mp4 input2.mp4

# Specify intensity level (1-5)
./datamosh.sh input1.mp4 input2.mp4 5

# Create a GIF alongside the video (because sharing MP4s is so 2024)
./datamosh.sh --gif input1.mp4 input2.mp4

# Show the help message when all else fails
./datamosh.sh --help
```

## Available Profiles

We have expertly crafted profiles that were definitely not created by randomly tweaking parameters:

- `glitch`: Light static-like artifacts. The "I just want a little chaos" option.
- `bloom`: Blooming color effects. Colors have a mind of their own.
- `smear`: Smearing/trailing effect. Like butter on toast, but pixels.
- `extreme`: Heavy distortion. For when you want your video to have an existential crisis.
- `rainbow`: Colorful patterns. Unicorns may or may not be involved.

## How It Works (Sort Of)

1. The script converts your videos to AVI format with the Xvid codec
2. It extracts portions of each video as raw binary data
3. It strategically damages the files by removing bytes at calculated positions
4. It concatenates the mangled data to create a glitchy transition
5. It converts the result back to MP4 for your viewing pleasure/confusion

Is this the most efficient way to do it? Absolutely not. Is it the most fun way? Debatable. Does it work? Sometimes! 

## Demo
https://github.com/user-attachments/assets/34ff2493-9be2-4b2c-85d0-51f2e39c6df6

## Troubleshooting

**Q: It doesn't work!**  
**A:** Have you tried turning it off and on again?

**Q: The output is just black!**  
**A:** Congratulations! You've created a very avant-garde piece of video art.

**Q: The video plays for 2 seconds then crashes my player!**  
**A:** That's not a bug, it's a feature. Your video is now too powerful for conventional players.

**Q: The output works but doesn't look glitchy enough!**  
**A:** Try the `extreme` profile or increase intensity. If that doesn't work, print your video on paper, soak it in water, and then scan it back in.

## Disclaimer

This script manipulates video files in ways they were never meant to be manipulated. It's like using a hammer to apply lipstick - technically possible, but probably not recommended by professionals.

By using this script you agree that:

1. You're using it entirely at your own risk
2. No warranties are provided, express or implied
3. The author is not responsible for any seizures, nausea, or existential dread caused by the output videos
4. Your videos had it coming anyway

## License

This project is licensed under the "Do Whatever You Want But Don't Blame Me" license, which is similar to MIT but with more shrugging emoticons.

## Contributions

Found a bug? Fixed a bug? Introduced a more interesting bug? Pull requests are welcome! Just remember that any contributions you make should maintain the spirit of "works sometimes, looks cool when it does."

## Acknowledgments

- Thanks to the compression algorithm designers who probably didn't anticipate their work being deliberately sabotaged for aesthetic purposes
- Special thanks to my GPU, which has been a good sport about this whole ordeal
- Shout out to everyone who said "that looks broken" when actually it was working perfectly

---

*Remember: If anyone asks you what you're doing, the correct answer is "advanced video compression research."*
