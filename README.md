# art-midi-notegen
Artistically generate random midi notes and CC. The object is to make the notes perform as unsyncronized as possible and by this art-midi-notegen is not performance optimized, as missing a beat is not an issue.

As it is almost just about sound (and/or music) the art-midi-notegen will not currently show any visual details in the main window, just deep black.

# Settings
On application start art-midi-notegen will check if there is any config files in folder "./data". art-midi-notegen is using three config files to seperate settings, main.json, note.json and cc.json. If the files do not exist on start they will be created using default settings.

art-midi-notegen will auto refresh settings on run, so make any changes in any of the settings files the changes will take effect in real time. The refresh settings can be changed in main.json.

**You can change any settings using the config files, a piece file, macro, or a composition file. So you can change current piece file inside a piece file, or a use a macro inside a macro.**

## data/main.json
The main config file for all global changes. Ex. settings refresh.

## data/notes.json
The note.json holds settings for the random midi note generator.

## data/cc.json
The cc.json holds settings for the random Controller Change (CC) generator.

## data/piece.json
The piece.json is use to compose movments, change config based on a time value.

Example what a short piece.json can look like:

```javascript
{
    "10000": {
        "note" : {
            "PITCH_MAX": 154
        }
    },
    "15000": {
        "note" : {
            "PITCH_MIN": 1,
            "PITCH_MAX": 32
        }
    },
    "23000": {
        "note" : {
            "VELOCITY_MAX": 123
        },
        "cc" : {
            "CC_GEN_DELAY_MAX": 5000
        }
    }
}
```
This will init a delay of `10000`ms and then change the `PITCH_MAX`. Next it will take a new delay of 15000-10000=5000ms and change the pitch again. When it reaches the end it will start over and so it will init the `10000`ms delay again.

Be aware if `USE_CONFIG_REFRESH` is set to `true`, then it will change settings found in main/note/cc json at the same time. You can set `USE_CONFIG_REFRESH` to `false`, or remove any used settings in piece from the other config files or just let i happen.

## Macro, pre defined configs
Macros can be used in the a piece file or in composer file (se below for more info). It makes it easier to re-use config changes and for the readability.

A json macro files can look like this:
```javascript
{
    "hello": {
        "note" : {
            "PITCH_MAX": 154
        }
    },
    "world": {
        "note" : {
            "PITCH_MIN": 1,
            "PITCH_MAX": 32
        },
        "cc" : {
            "CC_GEN_VALUE_MAX": 45,
            "CC_GEN_DELAY_MAX": 7500
        }
    }
}
```
Almost the same as a piece file - it just uses named blocks instead of a time value.

To use it a piece file you do like this:
```javascript
{
    "10000": {
        "note" : {
            "PITCH_MAX": 154
        }
    },
    "15000": {
        "macro" : [
            {
                "source": "macro.json",
                "do": ["hello", "world"]
            }
        ]
    },
    "20000": {
        "note" : {
            "GEN_NB_NOTES_MIN": 1,
            "GEN_NB_NOTES_MAX": 32
        },
        "macro" : [
            {
                "source": "macro.json",
                "do": ["hello"]
            }
        ]
    }
} 
```
You create a new `array` block call `macro` and inside the block you can but as many object macro objects as you wish. The macro object need a `source`, the file where the macros are defined and a `do` to point which macros in that file that should be called.

# Composition
A composition file is it's own file format made to make it simple to compose using pre defined macros.

An example of a composition file:
```
# This my first composition
macro macro.json
5 hello
10 world
15 hello world # This comment will be ignored
jmp 10 1
20 hello
22 world
# This line will be ignored and so will any empty lines and lines that have nothing useful


30 hello
```
The composition files starts by define which macro file to use. Then a time value in seconds and one or many named configs from the macro file to invoke at that delay value. And so the `hello` config changes from `macro.json` will be run after a delay of 5 seconds in this example. It will the go to the next row and pick a new delay. 

When the program reaches `jmp` it will jump to the defined delay value, in this case to `10`. The next following numbers are for how many times it should loop. In this case: two times, as it's also using 0 as one jump. If no loop counter value is defined it will loop once.

Safe comments are using `#` at the start of the comment line.

# Dependencies
art-midi-notegen is using Processing to run and the MidiBus library to create midi data. You can install MidiBus by using the  Processing IDE built in library manager (Sketch->Import Library->Add Library). 

Processing:
https://processing.org/

MidiBus:
http://www.smallbutdigital.com/projects/themidibus/
