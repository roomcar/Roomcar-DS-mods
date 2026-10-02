-- Screen-space geometry, including both rows of buttons below the slots.
local M = { LEFT = -285, RIGHT = 285, BOTTOM = -395, TOP = 345, MARGIN = 12 }

function M.IsFinite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end

function M.DecodePosition(data)
    if type(data) == "table" and M.IsFinite(data.x) and M.IsFinite(data.y) then
        return { x = math.max(0, math.min(1, data.x)), y = math.max(0, math.min(1, data.y)) }
    end
end

function M.Fit(width, height, sx, sy)
    return math.max(.001, math.min(1,
        math.max(1, width - 2 * M.MARGIN) / ((M.RIGHT - M.LEFT) * sx),
        math.max(1, height - 2 * M.MARGIN) / ((M.TOP - M.BOTTOM) * sy)))
end

function M.Clamp(x, y, width, height, sx, sy)
    local xmin, xmax = M.MARGIN - M.LEFT * sx, width - M.MARGIN - M.RIGHT * sx
    local ymin, ymax = M.MARGIN - M.BOTTOM * sy, height - M.MARGIN - M.TOP * sy
    x = xmin <= xmax and math.max(xmin, math.min(xmax, x)) or (xmin + xmax) / 2
    y = ymin <= ymax and math.max(ymin, math.min(ymax, y)) or (ymin + ymax) / 2
    return x, y
end

return M
