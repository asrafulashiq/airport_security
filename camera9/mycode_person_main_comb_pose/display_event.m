function [im, events] = display_event(R, h)

% get event
%
if ~isempty(R.Event)
    revent = R.Event;
    for k=1:size(revent,1)
        event = {};
        if  revent(k, 1) == 4
%             event.text = sprintf('P%d touches B%d', revent(k, 2), revent(k, 3));
%             event.frame_no = R.current_frame;
%             event.color = 'yellow';
        else
            event.text = sprintf('P%d touches another B%d', revent(k, 2), revent(k, 3));
            event.frame_no = R.current_frame;
            event.color = 'red';
            R.recent_events{end+1} = event;
        end
        
    end
end
% bin event
if ~isempty(R.R_bin.event)
    for i = 1:numel(R.R_bin.event)
        event = {};
        event.frame_no = R.current_frame;
        event.text = R.R_bin.event{i};
        event.color = 'yellow';
        R.recent_events{end+1} = event;
    end
end

% people event
if ~isempty(R.R_people.event)
    for i = 1:numel(R.R_people.event)
        event = {};
        event.frame_no = R.current_frame;
        event.text = R.R_people.event{i};
        event.color = 'yellow';
        R.recent_events{end+1} = event;
    end
end

w = 400;

im1 = uint8(ones(h, 200, 3) * 255);

im2 = uint8(ones(h, 300, 3) * 255);

no = 5;
per_h = round(2/3 * h / no);

cur = numel(R.recent_events);

pad = 15;

  im1 =  insertText(im1, [pad pad], 'Frame',  'FontSize', 35);

   im2 = insertText(im2, [pad pad], 'Event Info',  'FontSize', 35 );

for i = 1:no
    
    if cur <=0
        break;
    end 
    
    eve = R.recent_events{cur};
    
    x = pad;
    y = i*per_h;
    
    im1 = insertText(im1, [x y], sprintf('%04d',eve.frame_no), 'BoxColor', eve.color, 'FontSize', 25);
    
    im2 =insertText(im2, [x y], eve.text, 'BoxColor', eve.color, 'FontSize', 22 );
    
    cur = cur - 1;
    
end

im1 = insertText(im1, [pad (no+1)*pad], sprintf('%04d',R.current_frame), 'FontSize', 25);

im = cat(2, im1, im2);
events = R.recent_events;

end