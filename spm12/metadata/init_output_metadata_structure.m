function metastruc = init_output_metadata_structure(input_files, proc, output)
%==========================================================================
% PURPOSE: To create a metadata structure to be used for newly created
% output images.
%
% FORMAT: metastruc = init_output_metadata_structure(input_files, proc_params)
%   input_files = cell array containing input file names leading to the
%                   output image
%   proc = a structure containing the following fields:
%       .params     processing parameters
%       .version    version of the software used
%       .descrip    description of the processing step 
%   output = a structure containing the following fields:
%       .imtype     description of the output image 
%       .units      units of the output image
%   metastruc = a structure following the guidelines given in the metadata
%                   library manual (SPM12/metadata/doc)
%==========================================================================
% Written by Evelyne Balteau - Cyclotron Research Centre, 2017
%==========================================================================

metastruc = struct('history',struct('procstep',[],'input',[],'output',[]));
metastruc.history.procstep.descrip = proc.descrip;
metastruc.history.procstep.version = proc.version;
metastruc.history.procstep.procpar = proc.params;

if iscell(input_files)
    input_files = char(input_files);
end

for cinput = 1:size(input_files,1)
    filename = spm_file(input_files(cinput,:),'number','');
    metastruc.history.input{cinput}.filename = filename;
    hdr = get_metadata(filename);
    %if ~isempty(hdr{1}) %IRL crashes if there is no history field
    if isfield(hdr{1},'history')
        metastruc.history.input{cinput}.history = hdr{1}.history;
    else
        metastruc.history.input{cinput}.history = 'No history available.';
    end
end

metastruc.history.output.imtype = output.imtype;
metastruc.history.output.units = output.units;

end