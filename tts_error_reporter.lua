-- TTS Error Reporter
-- Add this to your TTS script to capture and format errors for easy copying

-- Copy this function and paste it at the very top of gyrinx2tts.lua in TTS
-- Then when errors occur, you can copy the formatted output

local ERROR_LOG = {}

-- Override the error logging to also capture to a copyable string
local originalErrorLog = errorLog
function errorLog(context, err)
    local timestamp = os.date("%H:%M:%S")
    local errorMsg = string.format("[%s] %s: %s", timestamp, context, tostring(err))
    
    table.insert(ERROR_LOG, errorMsg)
    
    -- Also call original error logging
    if originalErrorLog then
        originalErrorLog(context, err)
    else
        printToAll("[ERROR] " .. context .. ": " .. tostring(err), {1, 0, 0})
    end
end

-- Function to print all errors in a copyable format
function printErrors()
    if #ERROR_LOG == 0 then
        printToAll("No errors logged yet!", {0, 1, 0})
        return
    end
    
    printToAll("========== ERROR LOG ==========", {1, 1, 0})
    for i, err in ipairs(ERROR_LOG) do
        printToAll(err, {1, 0.5, 0.5})
    end
    printToAll("========== END LOG ==========", {1, 1, 0})
    printToAll("Select text above, right-click, and copy to VSCode", {0.7, 0.7, 1})
end

-- Function to clear error log
function clearErrors()
    ERROR_LOG = {}
    printToAll("Error log cleared", {0, 1, 0})
end

-- Function to save last error to a string you can copy
function getLastError()
    if #ERROR_LOG == 0 then
        return "No errors"
    end
    return ERROR_LOG[#ERROR_LOG]
end
