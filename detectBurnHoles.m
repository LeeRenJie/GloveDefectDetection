function resultImage = detectBurnHoles(inputImage)
    % Convert to grayscale
    grayImage = rgb2gray(inputImage);
    
    % Convert the grayscale image to a binary image using adaptive thresholding
    binary = imbinarize(grayImage, 'adaptive', 'ForegroundPolarity','dark','Sensitivity',0.4);
    
    % Perform morphological opening to remove noise 
    structuringElement = strel('disk', 17);
    cleanedImage = imopen(binary, structuringElement);
    
    % Label connected components in binary Image
    [connectedComponents, ~] = bwlabel(cleanedImage);
    
    % Extract properties of the connected components
    stats = regionprops(connectedComponents, 'Area', 'PixelIdxList');
    
    % Sort the connected components based on their area in descending order
    [~, sortedIdx] = sort([stats.Area], 'descend');
    
    % Initialize a binary mask to highlight burn holes within the objects
    holeMask = false(size(grayImage));
    
    % Skip the largest connected component and start iterating from the second largest
    % because the largest is often the background or main object, not a hole.
    for k = 2:length(sortedIdx)
        % Set the minimum area a hole needs to have to be considered significant.
        % Areas smaller than this threshold are ignored, assuming they're not relevant.
        holeAreaThreshold = 100; % pixels
        
        % Check if the current component's area exceeds the predefined threshold.
        % This step filters out very small areas that are unlikely to be considered holes.
        if stats(sortedIdx(k)).Area > holeAreaThreshold
            % If the area is larger than the threshold, mark the component as a hole.
            % This is done by setting the pixels corresponding to this component's
            % PixelIdxList in the 'holeMask' to true. PixelIdxList contains the linear indices
            % of the component's pixels in the image array.
            holeMask(stats(sortedIdx(k)).PixelIdxList) = true;
        end
    end

    
    % Dilate the hole mask to make the highlighted area thicker
    dilationElement = strel('disk', 17); % Adjust the size for thicker lines
    dilatedHoleMask = imdilate(holeMask, dilationElement);
    
    % Create an output image that overlays the detected holes on the original image
    resultImage = inputImage;
    redChannel = resultImage(:,:,1); % Extract the red channel
    redChannel(dilatedHoleMask) = 255; % Highlight holes in red
    resultImage(:,:,1) = redChannel; % Put the modified red channel back
    
    % No need to display the image here, as it will be displayed in an Image component
end