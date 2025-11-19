# gx-pwnbox
Are you tired of Kali? So am I. It seems very bloated and flacky to me. That made me create this repository to Kalify (pun intended :D) my Ubuntu machine automatically. It is almost actively being updated and more tools are being added to it.

## That's not it
It also sets up your Bash and VIM profile.

It makes Bash more like ZSH when it comes to completion, Also setup a nice PS1 with a fire indication in case of an error in the last command.

Regarding VIM - It makes it a comfortable IDE (to some extent) fo Python, C and Bash. It has also some nice shortcuts just to begin with.

I have not messed up much with the profiles so everyone can stick to their own.


## Setup
you have two modes for setup:
1. Core: It only installs very basic packages as well as VIM and Bash profiles
2. Attack: It goes wild and make your Ubuntu machine an attack station. (Choosing this mode will automatically perform a Core installtaion as well)

```
bash setup.sh core
bash setup.sh attack
```

## Troubleshooting
I have not made the script very error ressistent, but it just works and I am content with it. If you want to see what error you are encountering (the script will exit immediately in case of an error), see the file set by `ERROR_LOGS` variable (default is `/tmp/.gx_errors`)

## Contribution
You are very welcome to contribute :D
