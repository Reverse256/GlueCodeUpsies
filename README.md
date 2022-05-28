# GlueCodeUpsies

Tested with bash.

Copy the script into a $path directory if you wish.

### -Prerequisites:
- Install 'bc' for math operations ('sudo apt install bc' on debian based distros)
- Install upsies ( https://github.com/plotski/upsies )


### -Set-up
- Add 'localhost bB' to the hosts file
- configure upsies bB to have a random username & password


##### Variables at the top of the script:

- announce_url - Fill in. (Required)

- Temp_path - Path for several writes. Everything is saved here. (Required)

- Save_path - Copy the contents to a preferred directory (Blank if unused).

- Auto_open_after - Open the 2 text files with your default editor once it's ready. (Optional)

### -Usage:
./MTV.sh /path/to/file(s)

### -Output
Inside a directory named after the release contains: Final.txt, desc.txt, and the torrent file

- desc.txt
  - The Description. Copy all

- final.txt
  - Scene or not
  - Title
  - Tags
  - Poster Image url


##### Disclaimer: Confirm your uploads are up to standards.
