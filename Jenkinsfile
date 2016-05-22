
stage 'Dev'
node {
    checkout scm
    sh "mix deps.get"
}

stage 'QA'
node {
    sh "mix test"
}

node {
    echo "Deploying ${env.BRANCH_NAME}..."
}
