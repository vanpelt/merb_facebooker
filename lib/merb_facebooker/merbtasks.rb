namespace :facebooker do
  desc "Create a basic facebooker.yml configuration file"
  task :setup do   
    facebook_config = File.join(Merb.root,"config","facebooker.yml")
    unless File.exist?(facebook_config)
      cp File.dirname(__FILE__) + '/../../templates/config/facebooker.yml', facebook_config 
      puts "Configuration created in #{Merb.root}/config/facebooker.yml"
    else
      puts "#{Merb.root}/config/facebooker.yml already exists"
    end
  end
  
  namespace :tunnel do 
    # Courtesy of Christopher Haupt
    # http://www.BuildingWebApps.com
    # http://www.LearningRails.com
    desc "Create a reverse ssh tunnel from a public server to a private development server." 
    task :start => [ :config ] do  
      puts "Starting tunnel #{@public_host}:#{@public_port} to 0.0.0.0:#{@local_port}" 
      exec "ssh -nNT -g -R *:#{@public_port}:0.0.0.0:#{@local_port} #{@public_host_username}@#{@public_host}" 
    end 

    desc "Create a reverse ssh tunnel in the background. Requires ssh keys to be setup." 
    task :background_start => [ :config ] do  
      puts "Starting tunnel #{@public_host}:#{@public_port} to 0.0.0.0:#{@local_port}" 
      exec "ssh -nNT -g -R *:#{@public_port}:0.0.0.0:#{@local_port} #{@public_host_username}@#{@public_host} > /dev/null 2>&1 &" 
    end 
    
    # Adapted from Evan Weaver: http://blog.evanweaver.com/articles/2007/07/13/developing-a-facebook-app-locally/ 
    desc "Check if reverse tunnel is running"
    task :status => [ :config ] do
     if `ssh #{@public_host} -l #{@public_host_username} netstat -an | 
         egrep "tcp.*:#{@public_port}.*LISTEN" | wc`.to_i > 0
       puts "Seems ok"
     else
       puts "Down"
     end
    end

    task :config do
     facebook_config = File.dirname(__FILE__) + '/../../../../../config/facebooker.yml'
     FACEBOOKER = YAML.load_file(facebook_config)[Merb.environment]
     @public_host_username = FACEBOOKER['tunnel']['public_host_username'] 
     @public_host = FACEBOOKER['tunnel']['public_host'] 
     @public_port = FACEBOOKER['tunnel']['public_port'] 
     @local_port = FACEBOOKER['tunnel']['local_port'] 
    end
  end
end