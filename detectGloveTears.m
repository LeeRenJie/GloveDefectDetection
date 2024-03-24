function outputImage = detectGloveTears(inputImage)
    % Convert to grayscale
    grayImg = rgb2gray(inputImage);

    % Create a binary mask
    binaryImg = imbinarize(grayImg);
    binaryImg = imcomplement(binaryImg);

    % Denoise the binary image using morphological opening
    seOpen = strel('disk', 1);
    denoisedBinaryImg = imopen(binaryImg, seOpen);

    % Apply edge detection to the denoised binary image
    edges = edge(denoisedBinaryImg, 'Canny');

    % Apply morphological closing to connect fragmented edges
    seClose = strel('disk', 2);
    closedEdges = imclose(edges, seClose);

    % Crop the edge-detected image to focus on the relevant part
    heightOfCrop = floor(size(closedEdges, 1) * 0.75);
    croppedEdges = closedEdges(heightOfCrop:end, :);

    % Find the edges/boundaries on the edge-detected and cropped image
    [B, ~] = bwboundaries(croppedEdges, 'noholes');

    % Assuming the first boundary is the cuff's edge
    cuffBoundary = B{1};

    % Other processing steps omitted for brevity...
    % Calculate the angles between consecutive boundary points
    angles = atan2(diff(cuffBoundary(:,1)), diff(cuffBoundary(:,2)));

    % Calculate the difference in angle between consecutive segments
    angleDiffs = abs(diff(angles));

    % Normalize angle differences to the range [0, pi]
    angleDiffs = mod(angleDiffs, pi);

    % Define a range for the angle threshold to focus on pronounced "V" shapes
    lowerAngleThreshold = pi/6; % Lower bound
    upperAngleThreshold = pi/2;  % Upper bound

    % Find indices of angles within the defined range
    sharpAnglesIdx = find(angleDiffs > lowerAngleThreshold & angleDiffs < upperAngleThreshold) + 1;

    % Determine the distances between sharp angle points
    sharpPointDistances = sqrt(diff(cuffBoundary(sharpAnglesIdx,1)).^2 + diff(cuffBoundary(sharpAnglesIdx,2)).^2);
    distanceThreshold = 15; 
    
    % Find start and end indices of clumps
    clumpStartIdx = [1; find(sharpPointDistances > distanceThreshold) + 1];
    clumpEndIdx = [find(sharpPointDistances > distanceThreshold); length(sharpAnglesIdx)];
    
    % Filter out individual points not part of a clump
    clumps = clumpEndIdx - clumpStartIdx > 0;

    % Initialize the output image for drawing
    outputImage = inputImage; % Corrected from 'img' to 'inputImage'

    % Initialize arrays to store circle parameters
    circleCenters = [];
    circleRadii = [];
    
    for i = 1:length(clumps)
        if clumps(i)
            % Calculate the bounding box for each clump
            minX = min(cuffBoundary(sharpAnglesIdx(clumpStartIdx(i):clumpEndIdx(i)),2));
            maxX = max(cuffBoundary(sharpAnglesIdx(clumpStartIdx(i):clumpEndIdx(i)),2));
            minY = min(cuffBoundary(sharpAnglesIdx(clumpStartIdx(i):clumpEndIdx(i)),1)) + heightOfCrop;
            maxY = max(cuffBoundary(sharpAnglesIdx(clumpStartIdx(i):clumpEndIdx(i)),1)) + heightOfCrop;

            % Calculate center and radius for the clump
            center = [(minX + maxX) / 2, (minY + maxY) / 2];
            radius = max([(maxX - minX) / 2, (maxY - minY) / 2]) * 1.1;

            % Store center and radius
            circleCenters = [circleCenters; center];
            circleRadii = [circleRadii; radius];
        end
    end
    % Drawing the largest circle on the output image
    if ~isempty(circleRadii)
        [maxRadius, idxMaxRadius] = max(circleRadii);
        largestCircleCenter = circleCenters(idxMaxRadius, :);
        largestCircleRadius = maxRadius;

        % Call to custom circle drawing function
        color = [255, 0, 0]; % Red color for the circle
        thickness = 10; % Thickness of the circle's line
        outputImage = drawCircleOnImage(outputImage, largestCircleCenter(1), largestCircleCenter(2), largestCircleRadius, thickness, color);
    end
end

function img = drawCircleOnImage(img, centerX, centerY, radius, thickness, color)
    [rows, cols, ~] = size(img);
    [X, Y] = meshgrid(1:cols, 1:rows);

    for r = radius-thickness/2:radius+thickness/2
        mask = ((X - centerX).^2 + (Y - centerY).^2 <= r.^2) & ...
               ((X - centerX).^2 + (Y - centerY).^2 >= (r-thickness).^2);

        for k = 1:3 % For R, G, B channels
            channel = img(:,:,k);
            channel(mask) = color(k);
            img(:,:,k) = channel;
        end
    end
end