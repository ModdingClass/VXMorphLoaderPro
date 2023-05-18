# VXMorphLoaderPro
VX Lua Extension to load body morphs directly from obj files

![Logo for VXMorphLoaderPro](MLP.png)

### How To Install

Because of limited API available, sandbox reasons, etc. VX Morph Loader Pro is a LUA extension, not just a simple LUA Addon. 
In order to install it, you need to copy openstream_mlp.lua inside the Binaries folder.

Then, you must edit *openstream.lua*, find the **require** section 
example: 
```lua
require "openstream_add"
require "openstream_gfx"
```
and add the import for the new file as:
```lua
require "openstream_mlp"
```

Then in order to expose the call for the new code (Morph Loader Pro functionality), you have to make it available in the sandbox, so open *openstream_bsb.lua* and find: 
```lua
function sandbox()
    local ta = {
```

and at the end of this function, inside the **ta = { ... }** table, also add:

```lua    
MorphLoaderPro = MorphLoaderPro,
```
along the rest of the other exposed functions.



### How To Use
In your custom body addon, you should have your usual *update.lua* file.
Add block like below to enable Morph Loader Pro for that body (body740 as an example here):
```lua
MorphLoaderPro(
    "body740.bs",                           -- name of the body file (inside Scenes\Shared\Body folder)
    "MorphsBody740",                    -- morphs should be stored inside an extra folder (inside Scenes\Shared\Body folder), to prevent overriding caused by same name collision
    "ccPersonMorphLoaderPro_body740.bs" -- a Scripts\Shared\Person\ccPerson... file is required for using cc (Customizer) morphs, create it in your addon folder
)
```
Deploy obj files with your morphs inside *Scenes\Shared\Body\MorphsBody740* folder of the addon.
When deploying obj files, you can use the following preffixes to name your obj files.
```lua
--[[ 
    -- bbb_                     - stock morphs (shorthand for body_blends_body)
    -- body_blends_body_        - stock morphs
    -- aa_                      - auto applied morphs
    -- jcm_                     - joint corrective morphs
    -- expaf_                   - morphs that should be injected in anim01 and animface maybe?
    -- vxbody                   - morphs for PoseEdit Slider, no _
    -- vxhead                   - morphs for PoseEdit Slider, no _
    -- pe_                      - morphs for PoseEdit Slider
    -- cc_                      - morphs for Customizer
    -- emo_                     - morphs for Emotions
    -- ...
]]
```

Examples:

+ __emo__\_noseWrinkle.obj - because the prefix is emo_ this will be considered an Emotion and will be added to the emotions contextual menu.
+ __aa__\_SlightSmile.obj - because the prefix is aa_ this is considered an Always (Auto) Applied morph, so the BlendControl weight will be set at 1
+ __vxhead03__\_LeftGrin.obj - because the prefix starts with vxhead and is followed by 03 then it will be added to the game as a PoseEditor Slider, under VX Face sliders, with index 3

**jcm_** and **pe_** preffixes are the ones that also needs an associated *.acs* file with the same name as the *.obj* file. 
The *.acs* file is a text file with code for Ac scripts. For **jcm_** prefix it needs the AppExprLinear script included, for **pe_** prefix it needs sliders code and an AppExprLinear, but in fact it can contain anything.
