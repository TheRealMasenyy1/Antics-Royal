---
-- Module for creating Universally Unique Lexicographically Sortable Identifiers.
--
-- Modeled after the [ulid implementation by alizain](https://github.com/alizain/ulid). Please checkout the
-- documentation there for the design and characteristics of ulid.
--
-- @copyright Copyright 2016-2017 Thijs Schreijer
-- @license [mit](https://opensource.org/licenses/MIT)
-- @author Thijs Schreijer
-- @modified StevenDahFish

-- Crockford's Base32 https://en.wikipedia.org/wiki/Base32
local ENCODING = {
	"0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
	"A", "B", "C", "D", "E", "F", "G", "H", "J", "K", "M",
	"N", "P", "Q", "R", "S", "T", "V", "W", "X", "Y", "Z"
}
local ENCODING_LEN = #ENCODING
local TIME_LEN = 10
local RANDOM_LEN = 16


local floor = math.floor
local concat = table.concat
local random = Random.new(floor(os.clock() * 1000 + os.time()))
local now = function()
	return DateTime.now().UnixTimestampMillis / 1000
end

--- generates the time-based part of a `ulid`.
-- @param time (optional) time to generate the string from, in seconds since
-- unix epoch, with millisecond precision (defaults to now)
-- @param len (optional) the length of the time-based string to return (defaults to 10)
-- @return time-based part of `ulid` string
-- @name encode_time
local function encode_time(time, len) 
	time = floor((time or now()) * 1000)
	len = len or TIME_LEN
	
	local result = {}
	for i = len, 1, -1 do
		local mod = time % ENCODING_LEN
		result[i] = ENCODING[mod + 1]
		time = (time - mod) / ENCODING_LEN
	end
	return concat(result)
end

--- decodes the time-based part of a `ulid`.
-- @param ulid - a `ulid` string
-- @return in milliseconds since unix epoch
-- @name decode_time
function decode_time(ulid)
	local TIME_MAX = 281474976710655 -- max value for 48-bit number
	
	if string.len(ulid) ~= TIME_LEN + RANDOM_LEN then
		error("malformed ulid")
	end
	
	local timeStr = ulid:sub(1, TIME_LEN)
	local time = 0

	for i = 1, timeStr:len() do
		local char = timeStr:sub(-i, -i) -- Reverse index
		local encodingIndex = table.find(ENCODING, char)
		if encodingIndex == nil then
			error("invalid character found: " .. char)
		end

		time = time + (encodingIndex - 1) * math.pow(ENCODING_LEN, i - 1)
	end

	if time > TIME_MAX then
		error("malformed ulid, timestamp too large")
	end

	return time
end

--- generates the random part of a `ulid`.
-- @param len (optional) the length of the random string to return (defaults to 16)
-- @return random part of `ulid` string
-- @name encode_random
local function encode_random(len)
	len = len or RANDOM_LEN
	local result = {}
	for i = 1, len do
		result[i] = ENCODING[floor(random:NextNumber() * ENCODING_LEN) + 1]
	end
	return concat(result)
end

--- generates a `ulid`.
-- @param time (optional) time to generate the `ulid` from, in seconds since
-- unix epoch, with millisecond precision (defaults to now)
-- @return `ulid` string
-- @name ulid
-- @usage local ulid_mod = require(game.ReplicatedStorage.ULID)
local function ulid(time)
	return encode_time(time) .. encode_random()
end

local _M = {
	ulid = ulid,
	encode_time = encode_time,
	decode_time = decode_time,
	encode_random = encode_random
}

return setmetatable(_M, {
	__call = function(self, ...)
		return ulid(...)
	end
})