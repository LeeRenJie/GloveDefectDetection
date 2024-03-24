function outputImage = detectDirtOnGlove(inputImage)
    % Convert the image to the HSV color space
    hsvImg = rgb2hsv(inputImage);
    
    % Define the color ranges for the black glove in the HSV color space
    gloveValRange = [0.0 0.5]; % Black objects are in the lower half of the value range
    
    % Create a binary mask for the glove based on the value (brightness) range
    gloveMask = (hsvImg(:,:,3) >= gloveValRange(1)) & (hsvImg(:,:,3) <= gloveValRange(2));
    
    % Clean up the glove mask by removing small objects (noise) and filling in the gaps
    gloveMaskCleaned = imfill(bwareaopen(gloveMask, 50), 'holes');
    
    % Define the color ranges for detecting white dirt on the glove
    dirtSatRange = [0.0 0.5]; % Low saturation for white dirt
    dirtValRange = [0.6 1.0]; % High value (brightness) for white dirt
    
    % Create a binary mask for potential dirt grains based on saturation and value
    dirtMask = (hsvImg(:,:,2) >= dirtSatRange(1)) & (hsvImg(:,:,2) <= dirtSatRange(2)) & ...
               (hsvImg(:,:,3) >= dirtValRange(1)) & (hsvImg(:,:,3) <= dirtValRange(2));
    
    % Apply the glove mask to the dirt mask to ensure we only get dirt on the glove
    dirtOnGloveMask = dirtMask & gloveMaskCleaned;
    
    % Optional: Enhance detection of smaller dirt grains
    dirtOnGloveMaskCleaned = bwareaopen(dirtOnGloveMask, 1);
    
    % Perform closing operation to close small gaps within dirt clumps
    se = strel('disk', 10); 
    closedDirtMask = imclose(dirtOnGloveMaskCleaned, se);
    
    % Identify connected components in the cleaned binary mask
    cc = bwconncomp(closedDirtMask); 
    
    % Calculate properties of each connected component
    stats = regionprops(cc, 'Area', 'Centroid', 'BoundingBox');
    
    % Prepare the output image
    outputImage = inputImage;
    
    % Loop through each detected region to draw circles around dirt clumps
    for i = 1:length(stats)
        % Differentiate between single dots and clumps based on the area
        if stats(i).Area < 10000
            % For smaller areas (dots), use a smaller circle
            circleRadius = max(5, sqrt(stats(i).Area/pi)); 
        else
            % For larger areas (clumps), use the bounding box to determine the size of the circle
            boundingBox = stats(i).BoundingBox;
            diameter = sqrt(boundingBox(3)^2 + boundingBox(4)^2); % Diagonal of the bounding box
            circleRadius = diameter / 2; % Half of the diagonal as the radius
        end
        
        % Draw the circle on the original image. Adjust thickness and color as needed.
        color = [255, 0, 0]; % Red color for the circle
        thickness = 5; % Thickness of the circle's line
        outputImage = drawCircleOnImage(outputImage, stats(i).Centroid(1), stats(i).Centroid(2), circleRadius, thickness, color);
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