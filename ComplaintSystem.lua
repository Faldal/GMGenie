cmplSys = {};
cmplSys.temp = {};

cmplSys.status = {};
cmplSys.status.NONE = 0;
cmplSys.status.LOADING_LIST = 1;
cmplSys.status.LOADING_ONE = 2;
cmplSys.status.LOADED = 3;

cmplSys.formats={};
cmplSys.formats.CMPL_FORMAT_LIST = "|cffaaffaaComplaint|r:|cffaaccff (%d+).|r |cff00ff00Type|r:|cffffaa00 (.+)|r |cff00ff00Subject|r:|cffff4444(.+)|r |cff00ff00Created by|r:|cff00ccff(.+)|r |cff00ff00Created|r:|cff00ccff (%d*%a*%d*%a*%d*%a*%d*%a*) ago|r";
cmplSys.formats.CMPL_FORMAT_LIST_COMMENT = "|cff00ff00GM Comment|r:|cffff66cc .(.+).|r ";
cmplSys.formats.CMPL_FORMAT_CHAT_LOG = "|(.+)%((%a*)%) %- %[(.+) (.+)%] |r(.-)%[(.-)%].+%((%d+)%) (%a*)%]: (.+)";

cmplSys.commands = {};
cmplSys.commands.LIST = ".complaint list";
cmplSys.commands.VIEW = ".complaint view";
cmplSys.commands.ASSIGN = ".complaint assign";
cmplSys.commands.UNASSIGN = ".complaint unassign";
cmplSys.commands.CLOSE = ".complaint close";
cmplSys.commands.COMMENT = ".complaint comment";

--Init values
cmplSys.lastEditTime = 0;
cmplSys.status.current = cmplSys.status.NONE;
cmplSys.complaints = {};

function myChatFilterCompl(self, event, msg, author, ...)
	
	if(UnitName("Player") == "Pick" and msg:find("Bad movement")) then
		return true
	end
	
	if (not cIsLoaded()) then return end
	
	if (cmplSys.status.current == cmplSys.status.LOADING_LIST or cmplSys.status.current == cmplSys.status.LOADING_ONE) and cmplSys.lastEditTime > 0 and cmplSys.lastEditTime + 1 < GetTime() then
		-- Do not filter complains related messages from chat after LOADING_LIST them into chat.
		cmplSys.status.current = cmplSys.status.LOADED;
	end

	if(cmplSys.status.current == cmplSys.status.LOADING_LIST and msg:find(cmplSys.formats.CMPL_FORMAT_LIST)) then
		local _, _, cmplId, cmplType, cmplSubject, cmplCreatedBy, cmplCreated = msg:find(cmplSys.formats.CMPL_FORMAT_LIST)
		local cmplSubject = strtrim(cmplSubject);
		local cmplCreatedBy = strtrim(cmplCreatedBy);
		
		if msg:find(cmplSys.formats.CMPL_FORMAT_LIST_COMMENT) then
			 _,_,cmplGmComment = msg:find(cmplSys.formats.CMPL_FORMAT_LIST_COMMENT)
		else
			 cmplGmComment = "";
		end
		
		if msg:find("|cff00ff00Assigned To|r:|cff00ccff %a+|r") then
			 _,_,cmplAssignedTo = msg:find("|cff00ff00Assigned To|r:|cff00ccff (%a+)|r")
		else
			 cmplAssignedTo = "";
		end
		
		c = {
			id = cmplId,
			type = cmplType,
			subject = cmplSubject,
			createdBy = cmplCreatedBy,
			created = cmplCreated,
			gmComment = cmplGmComment,
			msg = msg,
			assigned = cmplAssignedTo,
			chatLog = {}
		};
				
		table.insert(cmplSys.complaints, c)
		cmplSys.lastEditTime = GetTime();
		cUpdateLeftList();
		return true;	
	elseif(cmplSys.status.current == cmplSys.status.LOADING_ONE and msg:find(cmplSys.formats.CMPL_FORMAT_CHAT_LOG)) then
		local _, _, cmplColor,cmplReporter, cmplDate, cmplTime, cmplChannelColor, cmplChannel, cmplNumber, cmplPlayerName, cmplMessage = msg:find(cmplSys.formats.CMPL_FORMAT_CHAT_LOG)
		--print("strSub: "..strsub(msg, strfind(msg, "()") + 1, strfind(msg, "()")+15))
		-- print(cmplColor..";"..cmplReporter..";"..cmplDate..";"..cmplTime..";"..cmplChannel..";"..cmplNumber..";"..cmplPlayerName..";"..cmplMessage)
		-- print(cmplTime.."|"..cmplColor.." ["..cmplChannel.."]: "..getPlayerLink(cmplPlayerName).." "..cmplMessage)
		
		
		-- print( "\124Hplayer:Pick\124h[Picktest]\124h" )
		local cChatMsg = {
			color = cmplColor,
			reporter = cmplReporter,
			date = cmplDate,
			time = cmplTime,
			cmplChannelColor = cmplChannelColor,
			channel = cmplChannel,
			guid = cmplNumber,
			name = cmplPlayerName,
			msg = cmplMessage
		}
		if(cChatMsg.color == "cff555500") then
			cChatMsg.color = "cffffffff";
		end
		-- print(cmplSys.status.current)
		table.insert(cmplSys.complaints[cmplSys.temp.loadingId].chatLog, cChatMsg)
		
		local v = cChatMsg; 
		messageFrame:AddMessage("|"..v.color..v.time.." ["..v.cmplChannelColor..v.channel.."]: "..getPlayerLink(v.name).." "..v.msg)
		-- messageFrame:AddMessage("|"..v.color..v.time..v.cmplChannelColor.." ["..v.channel.."]: ".."|"..v.color..getPlayerLink(v.name)..v.cmplChannelColor.." "..v.msg)
		
		cmplSys.lastEditTime = GetTime();

		return true;
	elseif((cmplSys.status.current == cmplSys.status.LOADING_ONE) and (msg:find(cmplSys.formats.CMPL_FORMAT_LIST) or  msg:find("Player subject") or msg:find("Chat history") or msg:find("Comment"))) then
		return true;
	elseif(msg:find("Closed by") and msg:find("Complaint")) then
		local _, _, cId = msg:find("|cffaaffaaComplaint|r:|cffaaccff (%d+)") -- /run myChatFilterCompl("","","Closed by |cffaaffaaComplaint|r:|cffaaccff 13.")
		
		local i = 1
		while cmplSys.complaints[i] do
			if(cmplSys.complaints[i].id == cId) then
				table.remove(cmplSys.complaints,i);
				break;
			end
			
			i = i + 1;
		end
		cUpdateLeftList();
		
		return false;
	elseif((msg:find("Assigned to") or msg:find("Unassigned by")) and msg:find("Complaint")) then
		getComplaintList();
		return false;
	elseif msg:find("|cff00ff00New complaint from|r|cffff00ff") and msg:find(":|r|cffff00ff %d+.|r") then
		getComplaintList();
		return false;
	end
end
ChatFrame_AddMessageEventFilter("CHAT_MSG_SYSTEM", myChatFilterCompl)
-- /run loadComplaints()
function getComplaintList()
	cmplSys.complaints = {};
	cmplSys.lastEditTime = GetTime();
	cmplSys.status.current = cmplSys.status.LOADING_LIST;
	
	SendChatMessage(cmplSys.commands.LIST);
end

-- /run getComplaint(10)
function getComplaintInfo(id)
	local complaint = cmplSys.complaints[id];
	
	cmplSys.status.current = cmplSys.status.LOADING_ONE ;
	cmplSys.lastEditTime = GetTime();
	cmplSys.temp.loadingId = id;
	
	cLblSubject:SetText(complaint.msg)
	
	SendChatMessage(cmplSys.commands.VIEW.." "..complaint.id);
end

function getPlayerLink(playerName)
   if playerName == nil then return "" end
	return  "\124Hplayer:"..playerName.."\124h["..playerName.."]\124h"
end
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
----UI Source: https://www.wowinterface.com/forums/showthread.php?t=42408 -------
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------

function cRemoveSelectedC()
	cmplSys.cSelected = {}
	messageFrame:Clear()
	cLblSubject:SetText("")

end

local frame  = CreateFrame("Frame", "PicksComplaintFrame", UIParent)
frame.width  = 625
frame.height = 350
frame:SetFrameStrata("DIALOG")
-- frame:SetScale(0.9)
frame:SetFrameLevel(0)
frame:SetSize(frame.width, frame.height)
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
frame:SetBackdrop({
	bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
	edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
	tile     = true,
	tileSize = 12,
	edgeSize = 12,
	insets   = { left = 3, right = 3, top = 3, bottom = 3}
})
frame:SetBackdropColor(0, 0, 0, 1)
frame:EnableMouse(true)
frame:EnableMouseWheel(true)

-- Make movable/resizable
frame:SetMovable(true)
frame:SetResizable(enable)
frame:SetMinResize(100, 100)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:SetClampedToScreen(true)

tinsert(UISpecialFrames, "PicksComplaintFrame")

function cShowComplaintSystem()
	if PicksComplaintFrame:IsShown() then
		PicksComplaintFrame:Hide();
	else
		getComplaintList();
		PicksComplaintFrame:Show();
		if (not cIsLoaded()) then cCreateLeftList(); end
	end
end

function cIsLoaded()
	return scrollBarLeft ~= nil;
end

---------- UI List
function cCreateBtnList(count)-- Load list button
	local topElement = frame;

	for variable = 0, count-1, 1 do
		local btnName = "cListBtn"..variable;
		
		_G[btnName] = CreateFrame("Button", nil, topElement, "GMGenie_LeftButton")
		if (topElement == frame) then
			--First button in relation to main frame
			_G[btnName]:SetPoint("TOPLEFT", 25, -30)
		else
			_G[btnName]:SetPoint("TOPLEFT", 00, -28)
		end
		_G[btnName]:RegisterForClicks("LeftButtonUp","RightButtonUp");
		_G[btnName]:SetHeight(25)
		_G[btnName]:SetWidth(175)
		_G[btnName]:SetFrameLevel(2)
		-- _G[btnName]:ButtonText():SetJustifyH("RIGHT"); -- /run print(_G["cListBtn1"]:IsEnabled()); /run _G["cListBtn1"]:SetHighlight(true)
		_G[btnName]:SetText("---")
		_G[btnName]:SetScript("OnClick", function(self)
			messageFrame:Clear()
			cmplSys.status.current = cmplSys.status.LOADED;
			cmplSys.cSelected = self.c;
			getComplaintInfo(self.value)
		end)
		_G[btnName]:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT");
                -- GameTooltip:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 150, -50);
                
                GameTooltip:AddLine("Created "..self.c.created.." ago");
				if (self.c.createdBy ~= nill and self.c.createdBy ~= "") then 
					GameTooltip:AddLine("by "..self.c.createdBy); 
				end
				if (self.c.gmComment ~= nill and self.c.gmComment ~= "") then 
					GameTooltip:AddLine("GM Comment: "..self.c.gmComment); 
				end
				if (self.c.assigned ~= nill and self.c.assigned ~= "") then 
					GameTooltip:AddLine("Assigned to: "..self.c.assigned); 
				end
                
                GameTooltip:Show();
		end)
		_G[btnName]:SetScript("OnLeave", function(self)
                GameTooltip:Hide();
		end)
		frame[btnName] = _G[btnName]
		topElement = _G[btnName];
	end
	
	
	local loadListBtn = CreateFrame("Button", nil, _G["cListBtn0"], "GMGenie_Button")
	loadListBtn:SetPoint("TOP",0, 27)
	loadListBtn:SetHeight(25)
	loadListBtn:SetWidth(100)
	loadListBtn:SetText("Reload list")
	loadListBtn:SetScript("OnClick", function(self)
		index = 0;
		getComplaintList();
		cRemoveSelectedC();
	end)
	frame.loadListBtn = loadListBtn
	
	local cCloseBtn = CreateFrame("Button", nil, frame, "GMGenie_Button")
	cCloseBtn:SetPoint("TOPRIGHT", 0, 0)
	cCloseBtn:SetHeight(18)
	cCloseBtn:SetWidth(18)
	cCloseBtn:SetText("X")
	cCloseBtn:SetScript("OnClick", function(self)
		cShowComplaintSystem();
	end)
	frame.cCloseBtn = cCloseBtn
end

function updateLeftButtons(startIndex)
	for btnId = 0, btnCount - 1, 1 do -- /run for i=1,50,1 do SendChatMessage(i); end
		local btnName = "cListBtn"..btnId;
		local cId = 1 + startIndex + btnId;
		local c = cmplSys.complaints[cId];
		
		if(c == nil) then 
			_G[btnName]:Hide()
			-- scrollBarLeft:Hide()
		else
			spaces =string.len(c.id) + string.len(c.type);
			if(c.type == "Language" or c.type == "Arena team") then
				spaces = spaces + 2
			end
			
			_G[btnName]:SetText(c.id.."  ["..c.type.."]".. string.rep(" ", 14 - spaces)..c.subject)
			
			if (c.gmComment ~= nill and c.gmComment ~= "") then 
					_G[btnName]:SetText(_G[btnName]:GetText().." |TInterface\\FriendsFrame\\InformationIcon:14:14:0:0|t")
			end
			if (c.assigned ~= nill and c.assigned ~= "") then 
					_G[btnName]:SetText(_G[btnName]:GetText().." |TInterface\\ChatFrame\\UI-ChatIcon-Blizz:12:20:0:0:32:16:4:28:0:16|t")
			end
			-- _G[btnName]:SetText(c.msg)
			_G[btnName].value = cId;
			_G[btnName].c = c;
			_G[btnName]:Show()
			scrollBarLeft:Show()
		end
	end
end

function cUpdateLeftList()
	cmplSys.temp.prevValue = -1;
	local max = getn(cmplSys.complaints) -1 -btnCount;
	if(max < 0) then
		max = 0;
	end
	updateLeftButtons(0);
	
	scrollBarLeft:SetMinMaxValues(0, max)
	
	scrollBarLeft:SetScript("OnValueChanged", function(self, value)
		if (cmplSys.temp.prevValue == value) then 
			return 
		end
		
		updateLeftButtons(value);
		cmplSys.temp.prevValue = value;
	end)
end

btnCount = 10;
cCreateBtnList(btnCount);

function cCreateLeftList()
	scrollBarLeft = CreateFrame("Slider", nil, frame, "UIPanelScrollBarTemplate")
	scrollBarLeft:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -40)
	scrollBarLeft:SetSize(30, frame.height - 90)

	scrollBarLeft:SetValueStep(1)
	scrollBarLeft.scrollStep = 1
	frame.scrollBarLeft = scrollBarLeft

	scrollBarLeft:SetScript("OnMouseWheel", function(self, delta)
		local cur_val = scrollBarLeft:GetValue()
		local min_val, max_val = scrollBarLeft:GetMinMaxValues()

		if delta < 0 and cur_val < max_val then
			cur_val = math.min(max_val, cur_val + 1)
			scrollBarLeft:SetValue(cur_val)
		elseif delta > 0 and cur_val > min_val then
			cur_val = math.max(min_val, cur_val - 1)
			scrollBarLeft:SetValue(cur_val)
		end
	end)
	scrollBarLeft:SetValue(0)
	
	cUpdateLeftList()
end

-- ScrollingMessageFrame
messageFrame = CreateFrame("ScrollingMessageFrame", nil, frame)
messageFrame:SetPoint("TOPRIGHT",-3, -30)
messageFrame:SetSize(400, frame.height - 90)
messageFrame:SetFontObject(ChatFontNormal)
messageFrame:SetTextColor(1, 1, 1, 1) -- default color
messageFrame:SetJustifyH("LEFT")
messageFrame:SetHyperlinksEnabled(true)
messageFrame:SetFading(false)
messageFrame:SetMaxLines(300)
frame.messageFrame = messageFrame

---------------------------------------------------------------------------
-- Scroll bar
-------------------------------------------------------------------------------
local scrollBar = CreateFrame("Slider", nil, frame, "UIPanelScrollBarTemplate")
scrollBar:SetPoint("LEFT", messageFrame, "LEFT", -25, -10)
scrollBar:SetSize(30, frame.height - 90)
scrollBar:SetMinMaxValues(0, 50)
scrollBar:SetValueStep(1)
scrollBar.scrollStep = 1
frame.scrollBar = scrollBar

scrollBar:SetScript("OnValueChanged", function(self, value)
	messageFrame:SetScrollOffset(select(2, scrollBar:GetMinMaxValues()) - value)
end)

scrollBar:SetValue(select(2, scrollBar:GetMinMaxValues()))

messageFrame:SetScript("OnMouseWheel", function(self, delta)
	-- print(messageFrame:GetNumMessages(), messageFrame:GetNumLinesDisplayed())

	local cur_val = scrollBar:GetValue()
	local min_val, max_val = scrollBar:GetMinMaxValues()

	if delta < 0 and cur_val < max_val then
		cur_val = math.min(max_val, cur_val + 1)
		scrollBar:SetValue(cur_val)
	elseif delta > 0 and cur_val > min_val then
		cur_val = math.max(min_val, cur_val - 1)
		scrollBar:SetValue(cur_val)
	end
end)

-- T
cLblSubject = frame:CreateFontString()
cLblSubject:SetPoint("TOP", messageFrame, 0, 30)
cLblSubject:SetHeight(40)
cLblSubject:SetWidth(350)
cLblSubject:SetFont(GameFontNormal:GetFont())
frame.cLblSubject = cLblSubject

local cEditBox = CreateFrame("EditBox", nil, messageFrame, "GMGenie_Input_Text")
cEditBox:SetPoint("BOTTOMLEFT", messageFrame, 0, -25)
cEditBox:SetHeight(25)
cEditBox:SetWidth(235)
frame.cEditBox = cEditBox;

local cCommentBtn = CreateFrame("Button", nil, messageFrame, "GMGenie_Button")
cCommentBtn:SetPoint("TOPRIGHT", cEditBox, 75, 0)
cCommentBtn:SetHeight(25)
cCommentBtn:SetWidth(75)
cCommentBtn:SetText("Comment")
cCommentBtn:SetScript("OnClick", function(self)
	if(cmplSys.cSelected == nil or cmplSys.cSelected.id == nil) then return end
	SendChatMessage(cmplSys.commands.COMMENT.." "..cmplSys.cSelected.id.." "..cEditBox:GetText());
	cEditBox:ClearFocus()
end)
frame.cCommentBtn = cCommentBtn

local cCloseBtn = CreateFrame("Button", nil, messageFrame, "GMGenie_Button")
cCloseBtn:SetPoint("BOTTOMLEFT", messageFrame, 0, -50)
cCloseBtn:SetHeight(25)
cCloseBtn:SetWidth(75)
cCloseBtn:SetText("Close")
cCloseBtn:SetScript("OnClick", function(self)
	if(cmplSys.cSelected == nil or cmplSys.cSelected.id == nil) then return end
	SendChatMessage(cmplSys.commands.CLOSE.." "..cmplSys.cSelected.id)
	cRemoveSelectedC();
end)
frame.cCloseBtn = cCloseBtn

local cAssignBtn = CreateFrame("Button", nil,messageFrame, "GMGenie_Button")
cAssignBtn:SetPoint("BOTTOMLEFT", messageFrame, 75, -50)
cAssignBtn:SetHeight(25)
cAssignBtn:SetWidth(75)
cAssignBtn:SetText("Assign")
cAssignBtn:SetScript("OnClick", function(self)
	if(cmplSys.cSelected == nil or cmplSys.cSelected.id == nil) then return end
	SendChatMessage(cmplSys.commands.ASSIGN.." "..cmplSys.cSelected.id.." "..UnitName("Player"))
end)
frame.cAssignBtn = cAssignBtn

local cUnassignBtn = CreateFrame("Button", nil, messageFrame, "GMGenie_Button")
cUnassignBtn:SetPoint("BOTTOMLEFT", messageFrame, 75*2, -50)
cUnassignBtn:SetHeight(25)
cUnassignBtn:SetWidth(75)
cUnassignBtn:SetText("Unassign")
cUnassignBtn:SetScript("OnClick", function(self)
	if(cmplSys.cSelected == nil or cmplSys.cSelected.id == nil) then return end
	SendChatMessage(cmplSys.commands.UNASSIGN.." "..cmplSys.cSelected.id.." "..UnitName("Player"))
end)
frame.cUnassignBtn = cUnassignBtn




