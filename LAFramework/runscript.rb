require 'xcodeproj'
class RunScriptConfigurator
    def self.post_install(installer)
        project = installer.aggregate_targets.first.user_project
        project.targets do |target|
            phase = target.new_shell_script_build_phase("Annotation Script")
            phase.shell_script = "Pods/LAFramework/LANetworking/Scripts/generate.sh\nPods/LAFramework/LAJsonKit/Scripts/json_generate.sh"
        end
        project.save()
    end
end