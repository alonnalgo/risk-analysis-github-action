/**
 * @param {import('probot').Probot} app
 */
 module.exports = (app) => {
    
  app.log("Yay! The app was loaded!");

  app.on('pull_request', async(context) => {
    app.log(`Listening to pull request \n ${JSON.stringify(context)} ` );
    createRiskAnalysis(context);
    runCI(context, 'pull_request');
  })


  
  async function runCI(context, source) {
  let headSha;

  if (source == "pull_request") {
    headSha = context.payload.pull_request.head.sha
  } 
  // Initialize a Check Run
  let checkRun = await createCheckRun(context, headSha)
  app.log("Finished check run");


  // Process Check Logic
  let result = await checkFileExtensions(context, source)
  app.log("Finished check file extensions");
  
  // Update Check with Resolution
  await resolveCheck(context, headSha, checkRun, result)
  app.log("Finished resolve check");

  }

  async function createCheckRun(context, headSha) {

  const startTime = new Date();

  return await context.octokit.checks.create({
    headers: {
      // accept: "application/vnd.github.v3+json"
      accept: "application/vnd.github.antiope-preview+json"
    },
    owner: process.env.OWNER,
    repo: process.env.REPO,
    name: " AlgoSec Code Analysis",
    status: "queued",
    started_at: startTime,
    head_sha: headSha,
    output: {
      title: "Queuing AlgoSec Code Analysis",
      summary: "The AlgoSec Code Analysis will begin shortly",
    },
  })
  }

  async function checkFileExtensions(context, source) {
  let owner = context.payload.repository.full_name.split('/')[0]
  let repo = context.payload.repository.name
  let pull_number = context.payload[source].number
  let per_page = 100
  
  // Returns a list of all changed files
  const changedFiles = await context.octokit.paginate(context.octokit.pulls.listFiles,{owner, repo, pull_number, per_page}) 
  
  // Loop through files and check for extension
  for (let file of changedFiles) {
    // Remove the directory structure and just get the file name
    let fileName = file.filename.split('/').pop()
    // Make sure that a split() on the filename results in an array of at minimum two
    // The first value should be the name of the file (before the dot) and the second should be its extension (after the dot)
    if (fileName.split('.').length < 2) {
      return "failure"
    }
  }
  // Could not find a reason to return false; therefore test is successful 
  return "success"
  }

  async function resolveCheck(context, headSha, checkRun, result) {
  
  await context.octokit.checks.update({
    headers: {
      accept: "application/vnd.github.antiope-preview+json"
      // accept: "application/vnd.github.v3+json"
    },
    owner: process.env.OWNER,
    repo: process.env.REPO,
    name: "AlgoSec Code Analysis",
    check_run_id: checkRun.data.id,
    status: "completed",
    head_sha: headSha,
    conclusion: result,
    output: {
      title: "AlgoSec Code Analysis Complete",
      summary: "Result is " + result,
    },
  })
  }

  async function createRiskAnalysis(context) {
      const issueComment = context.issue({
        body: "Risk Analysis Lambda GitHub App works!",
      });
    
      await context.octokit.issues.createComment(issueComment);
      app.log(`Finshed creating risk analysis`);

      
    }
};
