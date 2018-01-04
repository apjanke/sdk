// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// TODO(johnniwinther): Port this test to use the equivalence framework.

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:expect/expect.dart';
import 'type_mask_test_helper.dart';
import '../memory_compiler.dart';

const String TEST = """
returnInt1() {
  var a = 42;
  try {
    a = 54;
  } catch (e){
  }
  return a;
}

returnDyn1() {
  var a = 42;
  try {
    a = 'foo';
  } catch (e){
  }
  return a;
}

returnInt2() {
  var a = 42;
  try {
    a = 54;
  } catch (e){
    a = 2;
  }
  return a;
}

returnDyn2() {
  var a = 42;
  try {
    a = 54;
  } catch (e){
    a = 'foo';
  }
  return a;
}

returnInt3() {
  var a = 42;
  try {
    a = 54;
  } catch (e){
    a = 'foo';
  } finally {
    a = 4;
  }
  return a;
}

returnDyn3() {
  var a = 42;
  try {
    a = 54;
  } on String catch (e) {
    a = 2;
  } on Object catch (e) {
    a = 'foo';
  }
  return a;
}

returnInt4() {
  var a = 42;
  try {
    a = 54;
  } on String catch (e) {
    a = 2;
  } on Object catch (e) {
    a = 32;
  }
  return a;
}

returnDyn4() {
  var a = 42;
  if (a == 54) {
    try {
      a = 'foo';
    } catch (e) {
    }
  }
  return a;
}

returnInt5() {
  var a = 42;
  if (a == 54) {
    try {
      a = 42;
    } catch (e) {
    }
  }
  return a;
}

returnDyn5() {
  var a = 42;
  if (a == 54) {
    try {
      a = 'foo';
      print(a);
      a = 42;
    } catch (e) {
    }
  }
  return a;
}

returnInt6() {
  try {
    throw 42;
  } on int catch (e) {
    return e;
  }
  return 42;
}

returnDyn6() {
  try {
    throw 42;
  } catch (e) {
    return e;
  }
}

returnInt7() {
  var a = 'foo';
  try {
    a = 42;
    return a;
  } catch (e) {
  }
  return 2;
}

main() {
  returnInt1();
  returnDyn1();
  returnInt2();
  returnDyn2();
  returnInt3();
  returnDyn3();
  returnInt4();
  returnDyn4();
  returnInt5();
  returnDyn5();
  returnInt6();
  returnDyn6();
  returnInt7();
}
""";

void main() {
  runTest({bool useKernel}) async {
    CompilationResult result = await runCompiler(
        memorySourceFiles: {'main.dart': TEST},
        options: useKernel ? [Flags.useKernel] : []);
    Expect.isTrue(result.isSuccess);
    var compiler = result.compiler;
    var typesInferrer = compiler.globalInference.typesInferrerInternal;
    var closedWorld = typesInferrer.closedWorld;
    var commonMasks = closedWorld.commonMasks;

    checkReturn(String name, type) {
      MemberEntity element = findMember(closedWorld, name);
      Expect.equals(type,
          simplify(typesInferrer.getReturnTypeOfMember(element), closedWorld));
    }

    checkReturn('returnInt1', commonMasks.uint31Type);
    checkReturn('returnInt2', commonMasks.uint31Type);
    checkReturn('returnInt3', commonMasks.uint31Type);
    checkReturn('returnInt4', commonMasks.uint31Type);
    checkReturn('returnInt5', commonMasks.uint31Type);
    checkReturn(
        'returnInt6',
        new TypeMask.nonNullSubtype(
            closedWorld.commonElements.intClass, closedWorld));

    var subclassOfInterceptor = interceptorOrComparable(closedWorld);

    checkReturn('returnDyn1', subclassOfInterceptor);
    checkReturn('returnDyn2', subclassOfInterceptor);
    checkReturn('returnDyn3', subclassOfInterceptor);
    checkReturn('returnDyn4', subclassOfInterceptor);
    checkReturn('returnDyn5', subclassOfInterceptor);
    checkReturn('returnDyn6', commonMasks.dynamicType);
  }

  asyncTest(() async {
    print('--test from ast---------------------------------------------------');
    await runTest(useKernel: false);
    print('--test from kernel------------------------------------------------');
    await runTest(useKernel: true);
  });
}