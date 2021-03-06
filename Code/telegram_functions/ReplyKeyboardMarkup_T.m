function KeyboardMarkup = ReplyKeyboardMarkup_T(keyboard,varargin)
%ReplyKeyboardMarkup_T return object ReplyKeyboardMarkup. This object
%represents a custom keyboard with reply options (see Introduction to bots
%for details and examples).
% 
% keyboard	Cell Array of Cell Arrays of KeyboardButtons Cell Array of
% button rows, each represented by an Cell Array of KeyboardButton objects
% or simple text
% 
% resize_keyboard	Boolean	Optional. Requests clients to resize the
% keyboard vertically for optimal fit (e.g., make the keyboard smaller if
% there are just two rows of buttons). Defaults to false, in which case the
% custom keyboard is always of the same height as the app's standard
% keyboard.
% 
% one_time_keyboard	Boolean	Optional. Requests clients to hide the keyboard
% as soon as it's been used. The keyboard will still be available, but
% clients will automatically display the usual letter-keyboard in the chat
% – the user can press a special button in the input field to see the
% custom keyboard again. Defaults to false.
% 
% selective	Boolean	Optional. Use this parameter if you want to show the
% keyboard to specific users only. Targets: 1) users that are @mentioned in
% the text of the Message object; 2) if the bot's message is a reply (has
% reply_to_message_id), sender of the original message. Example: A user
% requests to change the bot's language, bot replies to the request with a
% keyboard to select the new language. Other users in the group don't see
% the keyboard.
% 
KeyboardMarkup = struct;
KeyboardMarkup.keyboard = keyboard;
KeyboardMarkup.resize_keyboard = false;
KeyboardMarkup.one_time_keyboard = false;
KeyboardMarkup.selective = false;
while ~isempty(varargin)
    switch lower(varargin{1})
        case 'resize_keyboard'
            KeyboardMarkup.resize_keyboard = varargin{2};
        case 'one_time_keyboard'
            KeyboardMarkup.one_time_keyboard = varargin{2};
        case 'selective'
            KeyboardMarkup.selective = varargin{2};
        otherwise
            error(['Unexpected option: ' varargin{1}])
    end
    varargin(1:2) = [];
end
end

