function outputImage = detectGloveTears(inputImage)
    % Convert input image to grayscale
    grayImg = rgb2gray(inputImage);

    % Binarize the grayscale image and then complement it
    binaryImg = imbinarize(grayImg);
    binaryImg = imcomplement(binaryImg);

    % Perform morphological opening to denoise the binary image
    seOpen = strel('disk', 1);
    denoisedBinaryImg = imopen(binaryImg, seOpen);

    % Detect edges using Canny method in the denoised binary image
    edges = edge(denoisedBinaryImg, 'Canny');

    % Perform morphological closing to fill gaps in edges
    seClose = strel('disk', 2);
    closedEdges = imclose(edges, seClose);

    % Crop the bottom 75% of the edge-detected image to focus on relevant area
    heightOfCrop = floor(size(closedEdges, 1) * 0.75);
    croppedEdges = closedEdges(heightOfCrop:end, :);

    % Find boundaries in the cropped, edge-detected image
    [B, ~] = bwboundaries(croppedEdges, 'noholes');

    % Assume the first boundary is the most significant, representing the cuff edge
    cuffBoundary = B{1};

    % Calculate angles between consecutive points on the boundary
    angles = atan2(diff(cuffBoundary(:,1)), diff(cuffBoundary(:,2)));

    % Calculate difference in angles to find changes in direction
    angleDiffs = abs(diff(angles));

    % Normalize differences to the range [0, pi]
    angleDiffs = mod(angleDiffs, pi);

    % Set thresholds to identify sharp angles indicative of tears
    lowerAngleThreshold = pi/6; % Lower bound for sharp angles
    upperAngleThreshold = pi/2; % Upper bound for sharp angles

    % Identify points with sharp angles within defined threshold
    sharpAnglesIdx = find(angleDiffs > lowerAngleThreshold & angleDiffs < upperAngleThreshold) + 1;

    % Calculate distances between points with sharp angles
    sharpPointDistances = sqrt(diff(cuffBoundary(sharpAnglesIdx,1)).^2 + diff(cuffBoundary(sharpAnglesIdx,2)).^2);
    distanceThreshold = 15; % Threshold to identify separate clumps of points

    % Determine start and end indices for clusters of sharp angles
    clumpStartIdx = [1; find(sharpPointDistances > distanceThreshold) + 1];
    clumpEndIdx = [find(sharpPointDistances > distanceThreshold); length(sharpAnglesIdx)];

    % Filter to identify actual clumps versus isolated points
    clumps = clumpEndIdx - clumpStartIdx > 0;

    % Prepare the original image for drawing indications of tears
    outputImage = inputImage; % Initialize output with the original image

    % Arrays to store center and radius of circles indicating tears
    circleCenters = [];
    circleRadii = [];

    for i = 1:length(clumps)
        if clumps(i)
            % Find bounding box of each tear-indicating clump
            minX = min(cuffBoundary(sharpAnglesIdx(clumpStartIdx(i):clumpEndIdx(i)),2));
            maxX = max(cuffBoundary(sharpAnglesIdx(clumpStartIdx(i):clumpEndIdx(i)),2));
            minY = min(cuffBoundary(sharpAnglesIdx(clumpStartIdx(i):clumpEndIdx(i)),1)) + heightOfCrop;
            maxY = max(cuffBoundary(sharpAnglesIdx(clumpStartIdx(i):clumpEndIdx(i)),1)) + heightOfCrop;

            % Calculate the center and radius for circles to draw around tears
            center = [(minX + maxX) / 2, (minY + maxY) / 2];
            radius = max([(maxX - minX) / 2, (maxY - minY) / 2]) * 1.1;

            % Store centers and radii for drawing
            circleCenters = [circleCenters; center];
            circleRadii = [circleRadii; radius]; %#ok<*AGROW>
        end
    end

    % Check if there are any identified circles (tears)
    if ~isempty(circleRadii)
        % Find the largest circle by radius
        [maxRadius, idxMaxRadius] = max(circleRadii);
        % Get the center of the largest circle
        largestCircleCenter = circleCenters(idxMaxRadius, :);
        % Set the radius for the largest circle
        largestCircleRadius = maxRadius;

        % Call a custom function to draw a red circle on the output image
        % indicating the most significant tear
        color = [255, 0, 0]; % Define the color of the circle as red
        thickness = 10; % Set the line thickness of the circle
        % Draw the circle on the image
        outputImage = drawCircleOnImage(outputImage, largestCircleCenter(1), largestCircleCenter(2), largestCircleRadius, thickness, color);
    end
end

function img = drawCircleOnImage(img, centerX, centerY, radius, thickness, color)
    % Get the dimensions of the image
    [rows, cols, ~] = size(img);
    % Create a grid of x,y coordinates
    [X, Y] = meshgrid(1:cols, 1:rows);

    % Iterate through each layer of thickness around the radius
    for r = radius-thickness/2:radius+thickness/2
        % Create a mask for the circle area
        mask = ((X - centerX).^2 + (Y - centerY).^2 <= r.^2) & ...
               ((X - centerX).^2 + (Y - centerY).^2 >= (r-thickness).^2);

        % Apply the mask to each color channel of the image
        for k = 1:3 % Loop through the RGB channels
            channel = img(:,:,k); % Select the current channel
            channel(mask) = color(k); % Apply the color to the masked area
            img(:,:,k) = channel; % Update the image channel
        end
    end
    % Return the image with the drawn circle
end