import jenkins.model.*
import hudson.model.*
import org.jenkinsci.plugins.workflow.job.*
import org.jenkinsci.plugins.workflow.cps.*
import hudson.plugins.git.*
import hudson.security.*

def jobName = "ApexPOS-Pipeline"
def gitRepo = "file:///var/jenkins_home/ApexPOS"
def branchSpec = "dev"

def jenkins = Jenkins.get()

// 1. Disable Security and CSRF Protection for local automation
jenkins.setSecurityRealm(SecurityRealm.NO_AUTHENTICATION)
jenkins.setAuthorizationStrategy(AuthorizationStrategy.UNSECURED)
jenkins.setCrumbIssuer(null)
println "✅ Disabled CSRF Protection and Security Realm"

// 2. Allow local directory checkouts for Git SCM
System.setProperty("hudson.plugins.git.GitSCM.ALLOW_LOCAL_CHECKOUT", "true")
println "✅ Allowed local Git SCM checkouts"

// 3. Configure Git safe.directory inside the container globally
try {
    def proc = ["git", "config", "--global", "--add", "safe.directory", "*"].execute()
    proc.waitFor()
    println "✅ Configured Git safe.directory globally inside the container"
} catch (Exception e) {
    println "⚠️ Failed to configure Git safe.directory: ${e.message}"
}

// 4. Create or update the Pipeline Job
def job = jenkins.getItem(jobName)
if (job == null) {
    job = jenkins.createProject(WorkflowJob.class, jobName)
    println "✅ Created Pipeline job: ${jobName}"
} else {
    println "✅ Pipeline job ${jobName} already exists, updating configuration"
}

def userRemoteConfig = new UserRemoteConfig(gitRepo, null, null, null)
def branchSpecObj = new BranchSpec("*/" + branchSpec)
def scm = new GitSCM(
    [userRemoteConfig],
    [branchSpecObj],
    false, [], null, null, []
)

def flowDefinition = new CpsScmFlowDefinition(scm, "Jenkinsfile")
job.setDefinition(flowDefinition)
job.save()
jenkins.save()
println "✅ Configured Pipeline job: ${jobName} with Git SCM pointing to ${gitRepo}#${branchSpec}"
