% function detectMissingFingers(inputImage)
%     % Convert the input image to the HSV color space for easier color segmentation
%     hsvImg = rgb2hsv(inputImage);
% 
%     % Define the HSV color range for detecting skin
%     skinHueRange = [0.0 0.09];
%     skinSaturationRange = [0.3 0.7];
%     skinValueRange = [0.3 0.9];
% 
%     % Create a binary mask identifying skin areas
%     skinMask = (hsvImg(:,:,1) >= skinHueRange(1)) & (hsvImg(:,:,1) <= skinHueRange(2)) & ...
%                (hsvImg(:,:,2) >= skinSaturationRange(1)) & (hsvImg(:,:,2) <= skinSaturationRange(2)) & ...
%                (hsvImg(:,:,3) >= skinValueRange(1)) & (hsvImg(:,:,3) <= skinValueRange(2));
% 
%     % Clean the mask by removing small objects
%     cleanedSkinMask = bwareaopen(skinMask, 6300);
% 
%     % Apply morphological closing
%     structuringElement = strel('disk', 100);
%     closedSkinMask = imclose(cleanedSkinMask, structuringElement);
% 
%     % Analyze the mask for missing fingers
%     connectedComponents = bwconncomp(closedSkinMask);
%     regionsStats = regionprops(connectedComponents, 'Area', 'Centroid', 'BoundingBox');
% 
%     % Prepare the output image
%     outputImage = inputImage;
%     imshow(outputImage); % Display the original image
%     hold on;
%     title('Detected Missing Fingers');
% 
%     % Check if there are any regions detected
%     if ~isempty(regionsStats)
%         % Iterate through detected regions to visualize them
%         for idx = 1:numel(regionsStats)
%             boundingBox = regionsStats(idx).BoundingBox;
%             diameter = max(boundingBox(3), boundingBox(4));
%             radius = diameter / 2;
%             centerPosition = regionsStats(idx).Centroid;
% 
%             % Draw circles around detected regions
%             viscircles(centerPosition, radius, 'Color', 'r', 'LineWidth', 1);
%         end
%     else
%         disp('No missing fingers detected.');
%     end
% 
%     hold off;
% 
%     % Note: Depending on how your application is set up, you might need to save the figure to an image file
%     % and then set this image file as the source for `app.outputimage`. Here's an example on how to do it:
%     % frame = getframe(gcf);
%     % imwrite(frame.cdata, 'outputImage.png');
%     % app.outputimage.ImageSource = 'outputImage.png';
% end
function outputImage = detectMissingFingers(inputImage)
    % Convert the input image to the HSV color space for easier color segmentation
    hsvImg = rgb2hsv(inputImage);

    % Define the HSV color range for detecting skin
    skinHueRange = [0.0 0.09];
    skinSaturationRange = [0.3 0.7];
    skinValueRange = [0.3 0.9];

    % Create a binary mask identifying skin areas
    skinMask = (hsvImg(:,:,1) >= skinHueRange(1)) & (hsvImg(:,:,1) <= skinHueRange(2)) & ...
               (hsvImg(:,:,2) >= skinSaturationRange(1)) & (hsvImg(:,:,2) <= skinSaturationRange(2)) & ...
               (hsvImg(:,:,3) >= skinValueRange(1)) & (hsvImg(:,:,3) <= skinValueRange(2));

    % Remove small objects from the mask
    MissFingerMaskCleaned = bwareaopen(skinMask, 6300);

    % Apply morphological closing to the mask
    structuringElement = strel('disk', 100);
    MissFingerMaskClosed = imclose(MissFingerMaskCleaned, structuringElement);

    % Analyze the closed mask to identify regions
    connectedComponents = bwconncomp(MissFingerMaskClosed);
    regionsStats = regionprops(connectedComponents, 'Area', 'Centroid', 'BoundingBox');

    % Prepare the output image
    outputImage = inputImage;

    % Define circle thickness
    circleThickness = 17; % Adjust for thicker or thinner circles

    for idx = 1:numel(regionsStats)
        center = regionsStats(idx).Centroid;
        boundingBox = regionsStats(idx).BoundingBox;
        diameter = max(boundingBox(3), boundingBox(4));
        radius = diameter / 2;
        
        % Calculate the circle mask with specified thickness
        circleMask = false(size(outputImage, 1), size(outputImage, 2));
        [columnsInImage, rowsInImage] = meshgrid(1:size(outputImage, 2), 1:size(outputImage, 1));
        distanceFromCenter = sqrt((rowsInImage - center(2)).^2 + (columnsInImage - center(1)).^2);
        circleMask = distanceFromCenter <= radius & distanceFromCenter >= (radius - circleThickness);

        % Apply the circle mask to the image, setting the outlined area to red
        for c = 1:3 % Apply to all three color channels for a red circle
            channel = outputImage(:,:,c);
            if c == 1
                channel(circleMask) = 255; % Set red channel to max
            else
                channel(circleMask) = 0; % Set green and blue channels to min
            end
            outputImage(:,:,c) = channel;
        end
    end
end