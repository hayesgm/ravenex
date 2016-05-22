
stage 'Dev'
node {
    checkout scm
    sh "mix deps.get"
}

stage 'QA'
node {
    echo "Testing ${env.BRANCH_NAME}..."
    sh "mix test"
}
