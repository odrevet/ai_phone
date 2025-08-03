# ai_phone

Phone your AI

## Getting Started

Setup local AI 

https://github.com/odrevet/odrevet/wiki/Local-AI

# Character card debug 

```sh
b64=$(identify -verbose "$1" | awk '/chara: /{flag=1; print substr($0, index($0,$2)); next} /^  [a-zA-Z_]/ {flag=0} flag {print}' | tr -d '\n')
echo "$b64" | base64 -d
```

