require 'xcodeproj'
class RunScriptConfigurator
    def self.post_install(installer)
        project = installer.aggregate_targets.first.user_project
        project.targets.each do |target|
            phases = target.shell_script_build_phases
            do_break = false
            phases.each do |phase|
                if (phase.name == "Annotation Script")
                    do_break=true
                    break
                end
            end
            next if do_break
            newPhase = target.new_shell_script_build_phase("Annotation Script")
            newPhase.shell_script = "Pods/LAFramework/LANetworking/Scripts/generate.sh\nPods/LAFramework/LAJsonKit/Scripts/json_generate.sh"
        end
        project.save()
    end


    
end