SuperDoc makes a nice local website to help you look at the npm packages you use. It currently can render their markdown docs. One day it will show api documentation and automatically docco-ify them. 

Since we're not yet in npm, do this for now to get started:

```
git clone https://github.com/mullr/SuperDoc
cd SuperDoc
npm link
```

Then go to some directory in your project which uses npm and type ```superdoc```. 

SuperDoc was developed on OSX and may work on other platforms as well. 
