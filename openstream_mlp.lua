--Morph Loader Pro - custom addon extension

local shouldAddEmotionsHeader = true
local shouldAddCustomizerHeader = true

local morphsFinalTable={}
local lastUsage=0

Global_MLP_CC =''


local function file_save3(fname,bsfile,len)
    fname = fname:gsub("%.%.","")
    local dir = fname:gsub("/[^/]+$","")
--    if  not fs.is(tmp_saves.."/"..addon_name.."/"..dir,"dir") then
--	fs.mkdir(tmp_saves.."/"..addon_name.."/"..dir,true)
 --   end
    file_save(addon_path.."/"..fname,bsfile,len)
    
    local sname=fname:lower()
    local tfile = new_file(sname) 
    tfile.tmp = addon_path.."/"..fname
end 

local function restrictToAddonContainedFiles(t, fnKeep)
    local j, n = 1, #t;

    for i=1,n do
        if (fnKeep(t, i, j)) then
            -- Move i's kept value to j's position, if it's not already there.
            if (i ~= j) then
                t[j] = t[i];
                t[i] = nil;
            end
            j = j + 1; -- Increment position of where we'll place the next kept value.
        else
            t[i] = nil;
        end
    end

    return t;
end

local function buildObjFilesList(path)
    local last_found_obj, obj_files = files_find(path.."'.*'.obj",true)
    restrictToAddonContainedFiles(obj_files, function(t, i, j)
        local v = t[i];
        if (v['aname'] == addon_name) then -- Keep addon file
            return true; -- Keep.
        else
            return false; -- Remove from array.
        end
    end);
    return obj_files
end

-- ######################################## UTILITIES BEGIN ###############################

function string:trim()
    return self:gsub("^%s+", ""):gsub("%s+$", "")
 end

function string:contains(sub)
    return self:find(sub, 1, true) ~= nil
end

function string:startswith(start)
    return self:sub(1, #start) == start
end

function string:endswith(ending)
    return ending == "" or self:sub(-#ending) == ending
end

local function table_contains(tbl, x)
    local found = false
    for _, v in pairs(tbl) do
        if v == x then 
            found = true 
        end
    end
    return found
end

local function getSimpleFileName(filename)
    return filename:match("[^/]*.obj$")
end

-- ######################################## UTILITIES END ###############################
--[[ 
CustomParameter :Parameter_MorpLoaderProTitle1A . {
    .ParamID I32(0);
    .Enable ( :EnableFemale || :EnableShemale );
    .ParamName "MorpLoaderProTitle1A";
    .ParamDescription " ";
    .CategoryID :Cat_Tattoo;
    .IconID I32(3523);
    .ParamType CustomParamType .Presets;
    .LookAtID :LookAtNone;
};
 ]]

local function initCcPersonHeader()

    if shouldAddCustomizerHeader then
        shouldAddCustomizerHeader = false
        local ccHeader = [[

        if ( ! defined ( :Parameter_MorpLoaderProHeader ) ) {
            CustomParameter :Parameter_MorpLoaderProHeader . {
                .ParamID I32(0);
                .Enable ( :EnableFemale || :EnableShemale || :EnableMale );
                .ParamDescription "---------------------------------[  Morph Loader Pro  ]---------------------------------";
                .ParamName "MorpLoaderProHeader";
            
                .CategoryID :Cat_Tattoo;
                .IconID I32(6500);
                .ParamType CustomParamType .Presets;
                .LookAtID :LookAtNone;
            };
        };
        ]]        
        return ccHeader
    end
    return ''
end

local function initEmotionsHeader()
    if shouldAddCustomizerHeader then
        shouldAddCustomizerHeader = false

        local menuPopup=[[
            if ( ! defined ( :PersonContext_Emotion_MorphLoaderPro_Item ) ) {
                WMenuItem :PersonContext_Emotion_MorphLoaderPro_Item . {
                    .Label "Morph Loader Pro";
                };	
                WPopup :PersonContext_Emotion_Popup .WidgetArray << WMenuItem :PersonContext_Emotion_MorphLoaderPro_Item;
            };

            if ( ! defined ( :PersonContext_Emotion_MorphLoaderPro_Popup ) ) {
                WPopup :PersonContext_Emotion_MorphLoaderPro_Popup . {
                    .Parent :PersonContext_Emotion_MorphLoaderPro_Item;
                    .Dimension :PopupDim;
                    .WidgetArray [ 	];
                    .HandlerArray [ WHandler . {
                        .Handle WEvent .ShowWidget;
                        .Cmd {
                            .Cmd "PersonContext_Cmd";
                            .SubCmd "BuildMenu_LookAt";
                            .Menu "GUI:PersonContext_Emotion_MorphLoaderPro_Popup";
                        };
                    };
                    ];
                };
            };
        ]]
          
        bsbpath = "Scripts/Shared/GUI/uiIngameContext01.bs"
        cb_insert(bsbpath,menuPopup,nil,nil)
            
        local emotionCategory = [[
            if ( ! defined ( :EmotionCategoryMorphLoaderPro ) ) {
                EmotionCategory :EmotionCategoryMorphLoaderPro . {
                    .CategoryID I32(2);
                    .Description "MLP emotions";
                    .UIElement "Browser_Category01_IconButton_Element";
                };
            };
        ]]
        bsbpath = "Scripts/Shared/EcEmotions.bs"
        cb_insert(bsbpath,emotionCategory,nil,nil)
    end
end



-- .ParamDescription "--------------------------------- Morph Loader Pro ---------------------------------";
local knownPreffixTable ={"bbb_", "aa_", "jcm_", "expaf_", "vxhead","vxbody", "cc_", "pe_", "emo_"}
local axisConversionTable ={"_rotx90", "_roty90", "_rotz90","_rotxm90", "_rotym90", "_rotzm90" }

local stockBlendControlsTable = {
	["body_blends_body_ear02"]={"853","808","655373"},
	["body_blends_body_ear01"]={"852","809","655372"},
	["body_blends_body_pregnant"]={"851","810","655371"},	
	["body_blends_body_atomic01"]={"850","811","655370"},
	["body_blends_body_vag".."ina".."fix_morph"]={"849","812","655369"},
	["body_blends_body_hentai01_morph"]={"848","813","655368"},
	["body_blends_body_capelli01_morph"]={"847","814","655367"},
	["body_blends_body_african01_morph"]={"846","815","655366"},
	["body_blends_body_jenna01_morph"]={"845","816","655365"},
	["body_blends_body_asian02_morph"]={"844","817","655364"},
	["body_blends_body_vag".."ina".."_morph"]={"843","818","655363"},
	["body_blends_body_asian01_morph"]={"842","819","655362"},
	["body_blends_body_eye_R_morph"]={"841","820","655361"},
	["body_blends_body_eye_L_morph"]={"840","821","655360"}
}

local function loadMorphInfoFromSceneFile(filename)
    ts{'load body scene file to string BEGIN'}
    local bodySceneString = file_load2(filename) --"Scenes/Shared/Body/body740.bs"
    ts{'load body scene file to string FINISH'}
    local meshDataBlendControl = string.match(bodySceneString,"MeshData%.BlendControl%s*%b[]%s*;")
    meshDataBlendControl = string.match(meshDataBlendControl, "%[(.-)%]") -- capture everything between  [ ]
    local bcTable={}
    for token in string.gmatch(meshDataBlendControl, "([^,]+),*%s*") do
        local sepIndex = token:find(":",1,true)
        token = token:sub(sepIndex+1)
        token = token:trim()
        bcTable[#bcTable+1] = token
    end 

    local function getBcIndex(name)
        local index 
        for k,v in ipairs(bcTable) do
        if v==name then
            index = k
            break
        end 
        end
        return index
    end



    local meshDataVertexData = string.match(bodySceneString,"MeshData%.VertexData%s*%b[]%s*;")
    meshDataVertexData = string.match(meshDataVertexData, "%[(.-)%]") -- If the captured string is not entirely composed of letters, use .- instead of %a+.
    local vdTable={}
    for token in string.gmatch(meshDataVertexData, "([^,]+),*%s*") do
        if token:find("VertexDataVector3f", 1, true) then
            local sepIndex = token:find(":",1,true)
            token = token:sub(sepIndex+1)        
            token = token:trim()
            vdTable[#vdTable+1] = token
        end
    end 

    local function getVdIndex(name)
        local index 
        for k,v in ipairs(vdTable) do
        if v==name then
            index = k
            break
        end 
        end
        return index
    end

    local extraBcTable = {}
    for w,q in bodySceneString:gmatch('\n%s*'..'BlendControl%s*:([%w_]*)'..'%s*.-Object%.Name%s-"([%w_]-)"') do
        if getBcIndex(w) then
            --ts{"%s > %s > %s ",w,q,vdTable[getBcIndex(w)]}
            extraBcTable[#extraBcTable +1] = {getBcIndex(w), w, q,vdTable[getBcIndex(w)]  }
        end
    end

    --[[ 
    VertexDataVector3f :local_821 . {
        VertexDataVector3f.DataArray Array_Vector3f [ (0, 0, 0),(0, 0, 0),(0, 0, 0),...,(0, 0, 0)];
        VertexData.Usage U32(655360);
    }; ]]

    local extraVdTable = {}
    for block in bodySceneString:gmatch('\n%s*'..'VertexDataVector3f%s*:[%w_]*'..'%s*%.%s*%b{}%s*;') do
        for w,q in block:gmatch('VertexDataVector3f%s*:([%w_]*)'..'%s*%.%s*{'..'.*U32%s*%((%d+)%)') do
            if getVdIndex(w) then
                --ts{"zoink %s > %s > %s ",w,q,vdTable[getVdIndex(w)]}
                extraVdTable[#extraVdTable +1] = {getVdIndex(w), w, q,vdTable[getVdIndex(w)]  }
            end
        end
    end
    local lastUsage = 0
    local finalTable = {}
    for kBc,vBc in ipairs(extraBcTable) do
        local activeIndex = tonumber(vBc[1])
        local localBcName = vBc[2]
        local objectName = vBc[3]
        local localVdName = vBc[4]
        local usage = 0
        for kVd,vVd in ipairs(extraVdTable) do
            if (localVdName == vVd[2]) then
                usage = tonumber(vVd[3])
                break
            end
        end
        finalTable[#finalTable+1] = {objectName, localBcName, localVdName, usage, activeIndex}
        --ts{"localVdName: %s U32(%s): ",localVdName,usage}
        if usage>lastUsage then lastUsage = usage end
        --ts{"lastUsage: %s",lastUsage}
    end
    return finalTable, lastUsage
end

local function getMeshDataVertexArrayContent(body_scene)
    local blockMeshData = false
    local foundBlockVertices = false
    local content = "" 
	for key,value in ipairs(body_scene) do
		if (value:find("MeshData :local_633")) then
            blockMeshData = true
		elseif (blockMeshData and value:find("MeshData.VertexArray%s?Array_Vector3f%s?%[")) then
			foundBlockVertices = true
            local startToken = value:find("%[")
            local endToken = value:find("%]")
            if (endToken) then
                content = value:sub(startToken+1,endToken-1)
                break
            else
                content = value:sub(startToken+1)
            end
		elseif (foundBlockVertices) then
			local endToken = value:find("%]")
            if (endToken) then
                content = content..value:sub(1, endToken-1)
                break
            else 
                content = content..value --no end token, lets continue to slurp
            end
		end
	end
	return content
end

local function getBasisMorphDataFromScene(body_scene)
    local meshDataVertexArrayContent = getMeshDataVertexArrayContent(body_scene)

    local vertArray = {}

    for vertexCo in meshDataVertexArrayContent:gmatch("%b()") do -- we find balanced () matches
        local s = vertexCo:sub(2,-2)    -- remove first and last characters the actual parantheses ()
        local x,y,z = string.match(s, '(%S+),%s+(%S+),%s+(%S+)') -- strings separated by commas
        vertArray[#vertArray+1]= { tonumber(x), tonumber(y), tonumber(z) }
    end
    return vertArray
end


local function getCustomMorphDataFromObj(filename)

    local obj_content = file_load2(filename,true)

    local foo = {}
    local vcount = 0
    for index, line in ipairs(obj_content) do
        if line:find("v ", 1, true) == 1 then
            local s = string.sub(line,3)
            local x,y,z = string.match(s, '(%S+)%s+(%S+)%s+(%S+)')
            foo[#foo+1]= { tonumber(x), tonumber(y), tonumber(z) }
        elseif (line:find("vt ", 1, true) == 1 or 
                line:find("vn ", 1, true) == 1 or 
                line:find("vp ", 1, true) == 1 or
                line:find("l ", 1, true) == 1 or
                line:find("f ", 1, true) == 1) then 
                -- we found a token and we should probably skip processing, cause we are done with the vertices by now
                -- ts ("vertex count: "..#foo)
                break
        end
    end
    return foo
end
local function calculateMorphDeltas(basisMorphData, customMorphData, mhasRotation)
    -- if there is a rotation/rotation matrix, we need to rotate the custom Morph
    local abs = math.abs
    local deltas= {}
    local counterEpsilon = 0
    local deltaX,deltaY,deltaZ = 0,0,0
    local epsilon = 0.000001
    local mepsilon = -epsilon
    for i=1,#customMorphData do
        deltaX = customMorphData[i][1]-basisMorphData[i][1]
        deltaY = customMorphData[i][2]-basisMorphData[i][2]
        deltaZ = customMorphData[i][3]-basisMorphData[i][3]
        if mepsilon<deltaX and deltaX<epsilon then deltaX = 0 end
        if mepsilon<deltaY and deltaY<epsilon then deltaY = 0 end
        if mepsilon<deltaZ and deltaZ<epsilon then deltaZ = 0 end
        deltas[#deltas + 1]= {deltaX,deltaY, deltaZ}
    end
    
    --surprise mofo, daz bodies can have extra vertices if there is an added geograft (maybe gens added?!?)
    for i=1,(#basisMorphData-#customMorphData) do
        deltas[#deltas + 1]= {0,0,0}
    end
    return deltas
end

local function loadFileContent (filename)
    local bodySceneString = file_load2(filename) --"Scenes/Shared/Body/body740.bs"
end

local function getMorphDetailsAndACSFromFilename(filename)
    local filenameWithoutExt = getSimpleFileName(filename):match("(.+)%..+$") -- remove everything after last period 
    
    local acsFile =filename:match("(.+)%..+$")..'.acs'
    local acExtra = file_load2(acsFile)
    acExtra = acExtra or ''

    local morphName = filenameWithoutExt
    morphName = morphName:gsub("%-", "_"); -- replace - with a _ character
    morphName = morphName:gsub("%.", "_"); -- replace . with a _ character
    morphName = morphName:gsub("[^%w_]+", ""); -- sanitize to keep only alpha numeric and _ chars
    local prefix = "grrr_" -- this is the angry preffix, you are not following the designation!!!
    local transform = "none"
    -- local knownPreffixTable ={"bbb_", "aa_", "jcm_", "expaf_", "pe_", "cc_", "vxhead", "vxbody"}

    for k,v in ipairs(knownPreffixTable) do
        if morphName:startswith(v) then
            if morphName:startswith("vxhead") or morphName:startswith("vxbody") then
                local peSliderLocation,peSliderNumber = morphName:match("vx(head)(%d+)_")    --   "%[(.-)%]") 
                if peSliderLocation == nil then
                    peSliderLocation,peSliderNumber = morphName:match("vx(body)(%d+)_")    --   "%[(.-)%]") 
                end
                if peSliderLocation ~= nil then
                    prefix = morphName:sub(1,#("vx"..peSliderLocation..peSliderNumber))
                    morphName = morphName:sub(#("vx"..peSliderLocation..peSliderNumber)+2)  -- count the _ and the +1 to advance 1 char
                end
            else 
                prefix = v
                morphName = morphName:sub(#prefix+1)
                break
            end  
        end
    end
    
    for k,v in ipairs(axisConversionTable) do
        if morphName:endswith(v) then
            transform = v:sub(2)
            morphName = morphName:sub(1, -(#v+1) )
            break  
        end
    end 
    return prefix,morphName, transform, acExtra
    
end

local function getMorphKnownData(morphName)
    for k,v in ipairs(morphsFinalTable) do
        if v[1] == morphName then
            return true, v[1],v[2],v[3],v[4],v[5]
        end
    end
    return false, nil, nil, nil, nil, nil
end

local function getAcScriptForVXPreffix(morphPrefix,morphName )
        local acSnippet = [[
            AppScript . {
                .MainContext True;
                .Script "
                    %s
                ";
            };]]

        local acSliderCode = ''
        local peSliderLocation,peSliderNumber = morphPrefix:match("vx(head)(%d+)")    --   "%[(.-)%]") 
        acSliderCode = [[
            ::GUI:PoseEdit_HeadTrack%s.Visibility 1u;
            ::GUI:PoseEdit_HeadMM%s_Label.Text \"%s\";
]]          
        if peSliderLocation == nil then
            peSliderLocation,peSliderNumber = morphPrefix:match("vx(body)(%d+)")    --   "%[(.-)%]") 
            acSliderCode = [[
                ::GUI:PoseEdit_BodyTrack%s.Visibility 1u;
                ::GUI:PoseEdit_Body%s_Label.Text \"%s\";
]]
        end
        if peSliderLocation ~= nil then
            -- lets beutify the morphName
            local sliderDescription = morphName:gsub("_", " ")  -- replace any _ with space 
            sliderDescription = sliderDescription:gsub("(%u)", " %1")   -- separate at UpperCase - add a space in front of every UpperCase => Upper Case
            sliderDescription = sliderDescription:gsub("%s+", " ")   -- remove double spacing with a single space
            sliderDescription = (" "..sliderDescription):gsub( "%W%l", string.upper):sub(2)  -- any word in string should be capitalized
            sliderDescription = sliderDescription:trim(sliderDescription)  
            sliderDescription =  'MLP '..sliderDescription
           
            local peShorterSliderNumber = peSliderNumber:gsub("^0","") -- we need to remove the 0 part if we have that
            acSliderCode = acSliderCode:format(peShorterSliderNumber,peShorterSliderNumber,sliderDescription)

            
            acSnippet = acSnippet:format(acSliderCode)..'\n'

            if #peSliderNumber==1 then                 -- single digit, we need to add a zero in front of the number ofr appexprlinear
                peSliderNumber='0'..peSliderNumber
            end
            local appExprLinearSnippet = [[
                AppExprLinear . {
                    .InputObjectNameArray [ "Person" + :person + "Anim:vx_%sMorph%s" ];
                    .InputAttrArray [ @ BlendControl .Weight ];
                    .CombineMatrixArray [ ( F32(1) , F32(0) , F32(0) , F32(0) , F32(0) , F32(0) , F32(0) , F32(0) , F32(0) , F32(0) , F32(0) , F32(0) , F32(0) , F32(0) , F32(0) , F32(0) ) ];
                    .OutputMin ( F32(0) , F32(0) , F32(0) , F32(0) );
                    .OutputMax ( F32(2) , F32(0) , F32(0) , F32(0) );
                    .OutputObjectName "Person" + :person + "Body:%s";
                    .OutputAttr @ BlendControl .Weight;
                    };
]]
            acSnippet=acSnippet..appExprLinearSnippet:format(peSliderLocation,peSliderNumber,morphName)
                else
                    return ''
        end
        

        return acSnippet
end


local function createStringForReplacingExistingMorph(deltas, morphPrefix, morphName, bcObjectName, bcName, vdName, usage, index )
    --template = template or '%d %s\n'
    local template = '(%f, %f, %f)'
    local tt = {}
    for k,v in ipairs(deltas) do
        template = '(%f, %f, %f)'
        if v[1]==0 and v[2]==0 and v[3]==0 then
            template = '(%d, %d, %d)'
        end
        tt[#tt+1]=template:format(v[1],v[2],v[3])
    end
    local vda =  table.concat(tt,',') 

    local vdBlock = [[
VertexDataVector3f :%s VertexDataVector3f.DataArray Array_Vector3f [ %s ];
]]
    vdBlock=vdBlock:format(vdName,vda)
--    local vdBlock = '\nVertexDataVector3f :'..vdName..' VertexDataVector3f.DataArray Array_Vector3f ['..vda..'];\n'

    local bodySnippet = vdBlock..'\n\n'
    local acSnippet = ''
    local ccSnippet = ''
    return bodySnippet, acSnippet, ccSnippet

end

local function createStringForAddingNewMorph(deltas, morphPrefix, morphName, usage, acExtra )

    --template = template or '%d %s\n'
    local template = '(%f, %f, %f)'
    local tt = {}
    for k,v in ipairs(deltas) do
        template = '(%f, %f, %f)'
        if v[1]==0 and v[2]==0 and v[3]==0 then
            template = '(%d, %d, %d)'
        end
        tt[#tt+1]=template:format(v[1],v[2],v[3])
    end
    local vda =  table.concat(tt,',') 

    --morphName= morphPrefix..morphName

    local bcBlock = ''
    if morphPrefix == "aa_" then
        bcBlock = [[ 
BlendControl :bc_%s . {
    BlendControl.Weight F32(1);
    BlendControl.StaticBlend I32(2);
    Object.Name "%s";
};
]]
        bcBlock = bcBlock:format(morphName,morphName)
    else
       -- bcBlock = bcBlock .. 'BlendControl :bc_'..morphName..' Object.Name "'..morphName..'";\n'
       bcBlock =[[
BlendControl :bc_%s Object.Name "%s";
]]
       bcBlock=bcBlock:format(morphName,morphName)
    end



    
    local vdBlock = [[
VertexDataVector3f :vd_%s . {
    VertexDataVector3f.DataArray Array_Vector3f [ %s ]; 
    VertexData.Usage U32(%d);
};    
]]
    vdBlock= vdBlock:format(morphName,vda,usage)

--[[     
    local vdBlock = 'VertexDataVector3f :vd_'..morphName..' . {\n'
    vdBlock = vdBlock .. '\tVertexDataVector3f.DataArray Array_Vector3f [ '..vda..'];\n' 
    vdBlock = vdBlock .. '\tVertexData.Usage U32('..usage..');\n'
    vdBlock = vdBlock .. '};\n' ]]

    local arrayConcatBlock =[[
MeshData :local_633 .VertexData << VertexDataVector3f :vd_%s;
MeshData :local_633 .BlendControl << BlendControl :bc_%s;
]]

    arrayConcatBlock = arrayConcatBlock:format(morphName,morphName)

    local bodySnippet = bcBlock..'\n'..vdBlock..'\n'..arrayConcatBlock..'\n\n'



    local acSnippet = ''
    if morphPrefix:startswith("vxhead") or morphPrefix:startswith("vxbody") then
        acSnippet = getAcScriptForVXPreffix(morphPrefix,morphName)
    elseif morphPrefix:startswith("pe_") then
        acSnippet = acExtra
    elseif morphPrefix:startswith("jcm_") then
        acSnippet = acExtra
    else
        -- do nothing
    end






    local ccSnippet= ''

    if morphPrefix == "customizer_" or morphPrefix == "cc_" then
        ccSnippet= [[
CustomParameter :%s . {
    .ParamID I32(0);
    .Enable :EnableFemale;
    .ParamName "%s";
    .ParamDescription "%s";
    .CategoryID :%s;
    .IconID I32(3523);
    .ParamType CustomParamType .Slider;
    .SliderDefault F32(0);
    .PoseBlendNameArray [ "Person" + :person + "Body:%s"];
    .PoseBlendMulAddArray [ ( F32(1) , F32(0) ) ];
    .PoseBlendClampArray [ ( F32(-1) , F32(1) ) ];;
    .LookAtID :LookAtNone;
};
]]   
        local customParameterName = 'Parameter_'..'MLP_'..morphName
        local paramName = 'MLP_'..morphName
        local paramDescription = 'MLP '..morphName:gsub("(%u)", " %1")
        local categoryID = 'Cat_Tattoo'
        --if morphPrefix == "czface_" then categoryID='Cat_Face' end
        local poseBlendNameArray = morphName
        ccSnippet = ccSnippet:format(customParameterName,paramName,paramDescription,categoryID,poseBlendNameArray)
    end


    local emotionContextMenuSnippet= nil
    local emotionSnippet= nil

    if morphPrefix == "emo_" then
        -- *************************************************************************************************
        emotionContextMenuSnippet= [[
            if ( ! defined ( :%s ) ) {
                WMenuItem :%s . {
                    .Label "%s";
                    .HandlerArray [ WHandler . {
                        .Handle WEvent .ButtonClicked;
                        .Cmd {
                            .Cmd "PersonContext_Cmd";
                            .SubCmd "Person_ShowExpression";
                            .Expression "%s";
                        };
                    };
                    ];
                };
            
                WPopup :PersonContext_Emotion_MorphLoaderPro_Popup .WidgetArray << WMenuItem :%s;
]]   
        --PersonContext_Emotion_MLP1_Item
        local itemName = 'PersonContext_Emotion_MLP_'..morphName..'_Item'
        local label = morphName:gsub("_", " ")  -- replace any _ with space 
        label = label:gsub("(%u)", " %1")   -- separate at UpperCase - add a space in front of every UpperCase => Upper Case
        label = label:gsub("%s+", " ")   -- remove double spacing with a single space
        label = (" "..label):gsub( "%W%l", string.upper):sub(2)  -- any word in string should be capitalized
        label = label:trim()  



        local expression = morphName
        emotionContextMenuSnippet = emotionContextMenuSnippet:format(itemName,itemName, label,expression,itemName)
        -- *************************************************************************************************
        emotionSnippet = [[
            EmotionDescription :%s . {
                .Description "%s";
                .Expression "%s";
                .DefaultValue F32(0);
                .AddSpeed F32(1);
                .SubSpeed F32(2);
                .PoseBlendName "Person" + :personID + "Body:%s";
                .EmotionIconID I32(321);
                .Category :EmotionCategoryMorphLoaderPro;
            };
            ]]
            local emotionName = 'EmotionMLP_'..morphName
            local description = label -- same as label above
            local poseBlendName = morphName
            emotionSnippet = emotionSnippet:format(emotionName,description, expression,poseBlendName)
    end    

    return bodySnippet, acSnippet, ccSnippet,emotionContextMenuSnippet, emotionSnippet

end


local function createMorphStringForBSInjection(morphPrefix, morphName, transform, deltas, acExtra)
    -- question: can this be made faster??! (2D array output to string concatenation)
    local exists, bcObjectName, bcName, vdName, usage, index = false,"","","",0,0
    local bodySnippet, acSnippet, ccSnippet, emotionContextMenuSnippet, emotionSnippet
    local peSliderLocation,peSliderNumber = nil,nil

    if (morphPrefix:find("bbb_", 1, true) == 1 or morphPrefix:find("body_blends_body_", 1, true) == 1) then
        -- the BlendControl is already here, we don't need to add it again
        morphPrefix = morphPrefix:gsub("bbb_","body_blends_body_")
        morphName  = "body_blends_body_"..morphName                -- we need to reconstruct the name back, readding the lost prefix
    elseif morphPrefix:find("aa_", 1, true) == 1 then
            morphName  = morphPrefix..morphName
    elseif morphPrefix:find("expaf_", 1, true) == 1 then
            morphName  = morphPrefix..morphName
    elseif morphPrefix:find("cc_", 1, true) == 1 or morphPrefix:find("customizer_", 1, true) == 1 then
        morphPrefix = 'cc_'
        morphName  = morphName 
    elseif morphPrefix:find("vxbody", 1, true) == 1 or morphPrefix:find("vxhead", 1, true) == 1 then
        morphName  = morphName
    elseif morphPrefix:find("jcm_", 1, true) == 1 then
        morphName  = morphPrefix..morphName
    elseif morphPrefix:find("pe_", 1, true) == 1 then
        morphName  = morphName                
    elseif morphPrefix:find("emo_", 1, true) == 1 then
        morphName  = morphName                
    else         
       -- morphName  = morphPrefix..morphName -- we still need to add the grrrr_ prefix, right? or not?!?
    end


    exists, bcObjectName, bcName, vdName, usage, index = getMorphKnownData(morphName)


    if (exists) then
        bodySnippet, acSnippet, ccSnippet = createStringForReplacingExistingMorph( deltas, morphPrefix, morphName, bcObjectName, bcName, vdName, usage, index )
    else
        lastUsage = lastUsage + 1
        bodySnippet, acSnippet, ccSnippet, emotionContextMenuSnippet, emotionSnippet = createStringForAddingNewMorph( deltas, morphPrefix, morphName, lastUsage, acExtra )
    end

    
    --ts{'bodySnippet: %s',bodySnippet}
    return bodySnippet, acSnippet, ccSnippet, emotionContextMenuSnippet, emotionSnippet

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
end




local runs = 0

function MorphLoaderPro(bodyFile, morphsFolder, ccPersonFile)
    runs = runs +1
    local a=1
    a=a+1
    ts {"Starting Morph Loader Pro for: %s",addon_name}
    ts {"Finding: %s",bodyFile}
    local scenePath = "Scenes/Shared/Body/"
    morphsFolder = morphsFolder or ''
    local bodySceneFile = scenePath..bodyFile          -- "Scenes/Shared/Body/body740.bs"
    local obj_folder_path = scenePath..morphsFolder      -- Scenes/Shared/Body/MorphsBody740
    -- this part we read the input file as a big string
    
    
    morphsFinalTable,lastUsage = loadMorphInfoFromSceneFile(bodySceneFile)

    -- and in this part, because we are lazy :( :( :( , we read the input file for processing as a table( file was loaded line by line)
    local body_scene = file_load2(bodySceneFile,false)
    local basisMorphData = getBasisMorphDataFromScene(body_scene)

    initEmotionsHeader()

    local obj_files = buildObjFilesList(obj_folder_path)
    ts {"List ready"}
    --local obj_folder = addon_path.."/Scenes/Shared/Body/"

    local bodySnippetsTable = {}
    local acSnippetsTable = {}
    local ccSnippetsTable = {}
    local emotionContextMenuSnippetsTable = {}
    local emotionSnippetsTable = {}

    for _, obj in ipairs(obj_files) do
        ts {"Loading vertex data from: %s",getSimpleFileName(obj['lname'])}
        local customMorphData = getCustomMorphDataFromObj (obj['lname'])

        local prefix, morphName, transform, acExtra = getMorphDetailsAndACSFromFilename(obj['lname'])
        ts{"morph: %s => %s / %s / %s",getSimpleFileName(obj['lname']),prefix, morphName, transform}

        local deltas = calculateMorphDeltas(basisMorphData,customMorphData, false)
        local bodySnippet,acSnippet, ccSnippet, emotionContextMenuSnippet, emotionSnippet  = createMorphStringForBSInjection(prefix, morphName,transform, deltas, acExtra)


        if bodySnippet then table.insert(bodySnippetsTable,bodySnippet) end
        if acSnippet then table.insert(acSnippetsTable,acSnippet) end
        if ccSnippet then table.insert(ccSnippetsTable,ccSnippet) end
        if emotionContextMenuSnippet then table.insert(emotionContextMenuSnippetsTable,emotionContextMenuSnippet) end
        if emotionSnippet then  table.insert(emotionSnippetsTable,emotionSnippet) end


    end

    local contents = ''

    if (#bodySnippetsTable > 0) then
        local contents = table.concat(bodySnippetsTable,"\n")
    -- ts {"contents : \n%s",contents}

        --local bsbpath = "Scenes/Shared/Body/body740.[bsb]"
        cb_insert(bodySceneFile,contents,nil,nil)
    end

    if (#ccSnippetsTable > 0) then
        contents = table.concat(ccSnippetsTable,"\n")

        contents =  initCcPersonHeader()..contents
        local scriptsPath = 'Scripts/Shared/Person/'
        cb_insert(scriptsPath..ccPersonFile,contents,nil,nil)
    end

    if (#acSnippetsTable > 0) then
        local acContents = table.concat(acSnippetsTable,"\n")

        local function ch_array()
            txt = table.concat(bs_old,"\n")
            txt = txt:gsub("ComponentArray (%b[]);",function (a) return "ComponentArray "..a:sub(1, -2)..acContents.."\n];\n" end)
            --debug = true
            add(txt)
        end
        cb_add(ch_array,nil,"Scripts/Luder/Person.G=01/AcBody740.bs")
    end

    if (#emotionContextMenuSnippetsTable > 0) then
        contents = table.concat(emotionContextMenuSnippetsTable,"\n")
        cb_insert('Scripts/Shared/GUI/uiIngameContext01.bs',contents,nil,nil)

        contents = table.concat(emotionSnippetsTable,"\n")
        cb_insert('Scripts/Shared/EcEmotions.bs',contents,nil,nil)
    end



    ts{"Morph Loader Pro instance %d finished for: %s",runs, bodyFile}



end
