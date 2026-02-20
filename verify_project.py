import json
import os
import sys

def main():
    try:
        with open('native/app/eqMac.xcodeproj/project.json', 'r') as f:
            project = json.load(f)
    except FileNotFoundError:
        print("Error: native/app/eqMac.xcodeproj/project.json not found")
        sys.exit(1)

    objects = project['objects']
    missing_files = []
    
    # Iterate over all file references
    for uuid, obj in objects.items():
        if obj.get('isa') == 'PBXFileReference':
            path = obj.get('path')
            if not path:
                # Some might be relative to group, skipping deep check but noting
                continue
            
            source_tree = obj.get('sourceTree', '<group>')
            
            # Simple check for absolute paths or SDKROOT (ignore SDK)
            if source_tree == 'SDKROOT':
                continue
                
            # For <group>, we need to resolve the path relative to project structure
            # This is complex without traversing the tree.
            # But we can check if the file exists ANYWHERE in native/app/Source or similar
            # Or assume path is relative to project folder if not absolute
            
            # Let's try heuristic: Check if file exists relative to project root (native/app)
            # Or native/app/Source
            
            # Actually, most files are relative to group.
            # But let's look for simple missing files that I might have deleted but kept ref
            
            # Skip framework/library files that are system
            if path.endswith('.framework') or path.endswith('.dylib') or path.endswith('.tbd'):
                continue
                
            # Check if file exists in file system (recursively find?)
            # Too slow.
            pass

    # Better approach: Check for files deleted in previous steps e.g. *DataBus.swift
    # I already did this via grep.
    
    # Let's check specifically for the files I added in previous steps to ensure they are correct
    added_files = [
        'AppModel.swift',
        'DeepEyeApp.swift',
        'DeepEyeRoot.swift',
        'DeepKnob.swift',
        'DesignSystem.swift',
        'PluginSelector.swift',
        'SpectrumProvider.swift'
    ]
    
    print("Checking added files...")
    for f in added_files:
        found = False
        for uuid, obj in objects.items():
            if obj.get('isa') == 'PBXFileReference' and obj.get('path') == f:
                found = True
                break
        if not found:
            print(f"File reference {f} MISSING in project file")
            missing_files.append(f)
        else:
            print(f"File reference {f} FOUND")
            
    # Check if they are in build phase
    root_uuid = project['rootObject']
    # find target
    target_uuid = project['objects'][root_uuid]['targets'][0]
    target = project['objects'][target_uuid]
    
    sources_phase = None
    for phase_uuid in target['buildPhases']:
        phase = project['objects'][phase_uuid]
        if phase['isa'] == 'PBXSourcesBuildPhase':
            sources_phase = phase
            break
            
    if sources_phase:
        print("Checking build phase inclusion...")
        for f in added_files:
            # Find file ref uuid
            file_ref_uuid = None
            for uuid, obj in objects.items():
                if obj.get('isa') == 'PBXFileReference' and obj.get('path') == f:
                    file_ref_uuid = uuid
                    break
            
            if file_ref_uuid:
                included = False
                for build_file_uuid in sources_phase['files']:
                    build_file = objects[build_file_uuid]
                    if build_file.get('fileRef') == file_ref_uuid:
                        included = True
                        break
                if not included:
                    print(f"File {f} NOT included in Sources build phase")
                    missing_files.append(f)
                else:
                    print(f"File {f} included in build phase")

    if missing_files:
        sys.exit(1)

if __name__ == '__main__':
    main()
