import util from "util"
import F from "fs"
import P from "path"
import YAML from "js-yaml"

messages = YAML.load F.readFileSync (P.join __dirname, "messages.yaml"), "utf8"

error = (key, ax...) -> new Error util.format messages[key], ax...

export { error }
