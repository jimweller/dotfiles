import java.io.{PrintWriter, File}

@main def run(cpgFile: String, outDir: String) = {

  importCpg(cpgFile)

  val outDirFile = new File(outDir)
  if (!outDirFile.exists()) outDirFile.mkdirs()

  // --- entities.jsonl ---
  val entitiesFile = new PrintWriter(new File(outDir, "entities.jsonl"))

  var classCount = 0
  var methodCount = 0

  // Non-external, non-lambda type declarations
  cpg.typeDecl
    .filterNot(_.isExternal)
    .filterNot(_.name.contains("<lambda>"))
    .filterNot(_.name.contains("$"))
    .foreach { td =>
      val name = td.name
      val fullName = td.fullName
      val file = td.filename
      val line = td.lineNumber.getOrElse(-1)
      val escapedName = name.replace("\"", "\\\"")
      val escapedFullName = fullName.replace("\"", "\\\"")
      val escapedFile = file.replace("\"", "\\\"")
      entitiesFile.println(s"""{"kind":"class","name":"$escapedName","fullName":"$escapedFullName","file":"$escapedFile","line":$line}""")
      classCount += 1
    }

  // Non-external, non-operator methods
  cpg.method
    .filterNot(_.isExternal)
    .filterNot(_.name.startsWith("<operator>"))
    .filterNot(_.name.startsWith("<init>"))
    .filterNot(_.name.startsWith("<clinit>"))
    .filterNot(_.name.contains("<lambda>"))
    .foreach { m =>
      val name = m.name
      val fullName = m.fullName
      val file = m.filename
      val line = m.lineNumber.getOrElse(-1)
      // Use typeDecl traversal to get containing class (avoids <empty> from astParentFullName)
      val className = m.typeDecl.name.headOption.getOrElse("_unknown_")
      val escapedName = name.replace("\"", "\\\"")
      val escapedFullName = fullName.replace("\"", "\\\"")
      val escapedFile = file.replace("\"", "\\\"")
      val escapedClass = className.replace("\"", "\\\"")
      entitiesFile.println(s"""{"kind":"method","name":"$escapedName","fullName":"$escapedFullName","className":"$escapedClass","file":"$escapedFile","line":$line}""")
      methodCount += 1
    }

  entitiesFile.close()

  // --- callgraph.csv ---
  val callgraphFile = new PrintWriter(new File(outDir, "callgraph.csv"))

  cpg.call
    .filterNot(_.name.startsWith("<operator>"))
    .foreach { c =>
      val calleeName = c.name
      val calleeMethod = c.methodFullName
      val file = c.file.name.headOption.getOrElse("_unknown_")
      val line = c.lineNumber.getOrElse(-1)

      // Get caller method and its containing class
      val callerMethod = c.method.name
      val callerClass = c.method.typeDecl.name.headOption.getOrElse("_unknown_")

      // Get callee class from the call's methodFullName (take up to last dot before method name)
      val calleeClass = {
        val fn = c.methodFullName
        val lastDot = fn.lastIndexOf('.')
        if (lastDot > 0) {
          val prefix = fn.substring(0, lastDot)
          val lastSegDot = prefix.lastIndexOf('.')
          if (lastSegDot >= 0) prefix.substring(lastSegDot + 1) else prefix
        } else "_unknown_"
      }

      val escapedFile = file.replace("|", "_")
      callgraphFile.println(s"$callerClass|$callerMethod|$calleeClass|$calleeName|$escapedFile|$line")
    }

  callgraphFile.close()

  // --- inheritance.csv ---
  val inheritanceFile = new PrintWriter(new File(outDir, "inheritance.csv"))

  cpg.typeDecl
    .filterNot(_.isExternal)
    .filterNot(_.name.contains("<lambda>"))
    .filterNot(_.name.contains("$"))
    .foreach { td =>
      td.inheritsFromTypeFullName.foreach { parent =>
        val child = td.name
        // Extract simple name from full parent name
        val parentSimple = {
          val lastDot = parent.lastIndexOf('.')
          if (lastDot >= 0) parent.substring(lastDot + 1) else parent
        }
        inheritanceFile.println(s"$child|$parentSimple")
      }
    }

  inheritanceFile.close()

  // --- entity-summary.txt ---
  val summaryFile = new PrintWriter(new File(outDir, "entity-summary.txt"))
  summaryFile.println(s"Classes: $classCount")
  summaryFile.println(s"Methods: $methodCount")
  summaryFile.println(s"Total entities: ${classCount + methodCount}")

  val callCount = cpg.call.filterNot(_.name.startsWith("<operator>")).size
  summaryFile.println(s"Call edges: $callCount")

  val inheritCount = cpg.typeDecl.filterNot(_.isExternal).filterNot(_.name.contains("<lambda>")).inheritsFromTypeFullName.size
  summaryFile.println(s"Inheritance edges: $inheritCount")

  summaryFile.close()

  println(s"Extraction complete: $classCount classes, $methodCount methods, $callCount calls, $inheritCount inheritance edges")
}
