function N = init_metadata(N, hdr, json)
% To create JSON-encoded metadata during DICOM to nifti conversion,
% including all acquisition parameters. The metadata can either (or both)
% be stored in the extended header of the nifti image or saved as a
% separate file. This function is called by spm_dicom_convert. In case of
% an extended nii header, the size of the JSON header is used to define a
% new offset (N.dat.offset) for the image data in the nifti file and the
% JSON header is written into the nifti file. The modified nifti object N
% is returned so the data can be written in it according to the new offset
% (in spm_dicom_convert). In case of a separate JSON file, N is returned
% unchanged.
%__________________________________________________________________________
% FORMAT N = init_metadata(N, hdr, json)
% hdr       a single matlab structure containing the header (from
%           spm_dicom_headers)
% N(input)  the nifti object created in spm_dicom_convert with file name
%           and default offset
% json      a structure with fields
%               extended: true/false -> JSON metadata are stored as
%                           extended header in the nii file.
%               separate: true/false -> JSON metadata are stored as a
%                           separate JSON file.
%               anonym: 'basic','full','none' (see spm_dicom_anonymise.m)
% N(output) the nifti object modified with extended header and
%           corresponding extended offset
%==========================================================================
% Evelyne Balteau, Cyclotron Research Centre, Li�ge, Belgium
%==========================================================================

% INITIALIZE AND ORGANIZE STRUCTURE WITH acqpar AND history FIELDS
version = sprintf('spm_dicom_convert.m - version %s - %s', spm('Ver','spm_dicom_convert.m',true), spm('Version'));
metadata.history.procstep = struct('descrip','dicom to nifti import', 'version', version, 'procpar', []);
metadata.history.input{1} = struct('filename','AnonymousFileName', 'history',[]);
if isfield(hdr,'ImageType')
    metadata.history.output = struct('imtype',hdr.ImageType, 'units','a.u.');
else
    metadata.history.output = struct('imtype','Unprocessed MR image', 'units','a.u.');
end

hdr = spm_dicom_anonymise(hdr,struct('anonym',json.anonym));
metadata.acqpar = hdr;        


% only bother with the following if the jhdr isn't empty
if json.extended
    % JSONify the header
    jhdr = spm_jsonwrite(metadata, struct('indent','\t'));
    % a few parameters:
    % standard header is always 348 bytes long:
    std_hdr_size = 348;
    % the 'extension' array field (bytes 348-351)
    isHdrExtended = [1 0 0 0]; % [0 0 0 0] if no extended header is present
    % the extension includes the json header + two 32-bit numbers = 8 bytes
    % (the size of the extension and the ID of the extension):
    ext_hdr_size = length(jhdr)+8;
    % ID of the extension (32-bit number) = anything > 4, arbitrarily set
    % to 27 for now, just because I like this number :)...
    ext_hdr_id = 27;
    % the offset must be >352+ext_hdr_size and a multiple of 16
    offset = ceil((352+ext_hdr_size)/16)*16;
    
    % modify the offset to write data in the nifti file
    N.dat.offset = offset;
    % since offset has been modified, N must be re-created:
    create(N);
    
    % open nifti file to write the extended header
    fid = fopen(N.dat.fname,'r+');
    % standard header is always 348 bytes long, move first there:
    fseek(fid, std_hdr_size, 'bof');
    % the next 4 bytes indicate whether there is an extension.
    fwrite(fid,isHdrExtended,'uint8');
    % we should now be @byte 348+4 = 352: ftell(fid)
    % write the 32-bit numbers
    fwrite(fid,ext_hdr_size,'uint32');
    fwrite(fid,ext_hdr_id,'uint32');
    % we should now be @byte 348+4+8 = 360: ftell(fid)
    % write the jhdr
    fprintf(fid,'%s',jhdr); % disp(jhdr);
    fclose(fid);
end

if json.separate
    [pth,fnam,~] = fileparts(N.dat.fname);
    spm_jsonwrite(fullfile(pth,[fnam '.json']),metadata, struct('indent','\t'));
end

