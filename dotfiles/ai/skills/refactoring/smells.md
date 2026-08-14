# Code Smells

The 23 code smells catalogued on refactoring.guru, grouped into 6 families. Each entry: how to recognize it (Signs) and which refactorings treat it (Treatment). Use this to diagnose; then apply the named techniques from techniques.md.

## Bloaters

### Long Method

**Signs and symptoms:** A method contains too many lines of code. Generally, any method longer than ten lines should make you start asking questions.

**Treatment:** As a rule of thumb, if you feel the need to comment on something inside a method, you should take this code and put it in a new method. Even a single line can and should be split off into a separate method, if it requires explanations. And if the method has a descriptive name, nobody will need to look at the code to see what it does. To reduce the length of a method body, use Extract Method. If local variables and parameters interfere with extracting a method, use Replace Temp with Query, Introduce Parameter Object or Preserve Whole Object. If none of the previous recipes help, try moving the entire method to a separate object via Replace Method with Method Object. Conditional operators and loops are a good clue that code can be moved to a separate method. For conditionals, use Decompose Conditional. If loops are in the way, try Extract Method.

### Large Class

**Signs and symptoms:** A class contains many fields/methods/lines of code.

**Treatment:** When a class is wearing too many (functional) hats, think about splitting it up: Extract Class helps if part of the behavior of the large class can be spun off into a separate component. Extract Subclass helps if part of the behavior of the large class can be implemented in different ways or is used in rare cases. Extract Interface helps if it's necessary to have a list of the operations and behaviors that the client can use. If a large class is responsible for the graphical interface, you may try to move some of its data and behavior to a separate domain object. In doing so, it may be necessary to store copies of some data in two places and keep the data consistent. Duplicate Observed Data offers a way to do this.

### Primitive Obsession

**Signs and symptoms:** Use of primitives instead of small objects for simple tasks (such as currency, ranges, special strings for phone numbers, etc.) Use of constants for coding information (such as a constant USER_ADMIN_ROLE = 1 for referring to users with administrator rights.) Use of string constants as field names for use in data arrays.

**Treatment:** If you have a large variety of primitive fields, it may be possible to logically group some of them into their own class. Even better, move the behavior associated with this data into the class too. For this task, try Replace Data Value with Object. If the values of primitive fields are used in method parameters, go with Introduce Parameter Object or Preserve Whole Object. When complicated data is coded in variables, use Replace Type Code with Class, Replace Type Code with Subclasses or Replace Type Code with State/Strategy. If there are arrays among the variables, use Replace Array with Object.

### Long Parameter List

**Signs and symptoms:** More than three or four parameters for a method.

**Treatment:** Check what values are passed to parameters. If some of the arguments are just results of method calls of another object, use Replace Parameter with Method Call. This object can be placed in the field of its own class or passed as a method parameter. Instead of passing a group of data received from another object as parameters, pass the object itself to the method, by using Preserve Whole Object. But if these parameters are coming from different sources, you can pass them as a single parameter object via Introduce Parameter Object.

### Data Clumps

**Signs and symptoms:** Sometimes different parts of the code contain identical groups of variables (such as parameters for connecting to a database). These clumps should be turned into their own classes.

**Treatment:** If repeating data comprises the fields of a class, use Extract Class to move the fields to their own class. If the same data clumps are passed in the parameters of methods, use Introduce Parameter Object to set them off as a class. If some of the data is passed to other methods, think about passing the entire data object to the method instead of just individual fields. Preserve Whole Object will help with this. Look at the code used by these fields. It may be a good idea to move this code to a data class.

## Object-Orientation Abusers

### Switch Statements

**Signs and symptoms:** You have a complex switch operator or sequence of if statements.

**Treatment:** To isolate switch and put it in the right class, you may need Extract Method and then Move Method. If a switch is based on type code, such as when the program's runtime mode is switched, use Replace Type Code with Subclasses or Replace Type Code with State/Strategy. After specifying the inheritance structure, use Replace Conditional with Polymorphism. If there aren't too many conditions in the operator and they all call same method with different parameters, polymorphism will be superfluous. If this case, you can break that method into multiple smaller methods with Replace Parameter with Explicit Methods and change the switch accordingly. If one of the conditional options is null, use Introduce Null Object.

### Temporary Field

**Signs and symptoms:** Temporary fields get their values (and thus are needed by objects) only under certain circumstances. Outside of these circumstances, they're empty.

**Treatment:** Temporary fields and all code operating on them can be put in a separate class via Extract Class. In other words, you're creating a method object, achieving the same result as if you would perform Replace Method with Method Object. Introduce Null Object and integrate it in place of the conditional code which was used to check the temporary field values for existence.

### Refused Bequest

**Signs and symptoms:** If a subclass uses only some of the methods and properties inherited from its parents, the hierarchy is off-kilter. The unneeded methods may simply go unused or be redefined and give off exceptions.

**Treatment:** If inheritance makes no sense and the subclass really does have nothing in common with the superclass, eliminate inheritance in favor of Replace Inheritance with Delegation. If inheritance is appropriate, get rid of unneeded fields and methods in the subclass. Extract all fields and methods needed by the subclass from the parent class, put them in a new superclass, and set both classes to inherit from it (Extract Superclass).

### Alternative Classes with Different Interfaces

**Signs and symptoms:** Two classes perform identical functions but have different method names.

**Treatment:** Try to put the interface of classes in terms of a common denominator: Rename Methods to make them identical in all alternative classes. Move Method, Add Parameter and Parameterize Method to make the signature and implementation of methods the same. If only part of the functionality of the classes is duplicated, try using Extract Superclass. In this case, the existing classes will become subclasses. After you have determined which treatment method to use and implemented it, you may be able to delete one of the classes.

## Change Preventers

### Divergent Change

**Signs and symptoms:** You find yourself having to change many unrelated methods when you make changes to a class. For example, when adding a new product type you have to change the methods for finding, displaying, and ordering products.

**Treatment:** Split up the behavior of the class via Extract Class. If different classes have the same behavior, you may want to combine the classes through inheritance (Extract Superclass and Extract Subclass).

### Shotgun Surgery

**Signs and symptoms:** Making any modifications requires that you make many small changes to many different classes.

**Treatment:** Use Move Method and Move Field to move existing class behaviors into a single class. If there's no class appropriate for this, create a new one. If moving code to the same class leaves the original classes almost empty, try to get rid of these now-redundant classes via Inline Class.

### Parallel Inheritance Hierarchies

**Signs and symptoms:** Whenever you create a subclass for a class, you find yourself needing to create a subclass for another class.

**Treatment:** You may de-duplicate parallel class hierarchies in two steps. First, make instances of one hierarchy refer to instances of another hierarchy. Then, remove the hierarchy in the referred class, by using Move Method and Move Field.

## Dispensables

### Comments

**Signs and symptoms:** A method is filled with explanatory comments.

**Treatment:** If a comment is intended to explain a complex expression, the expression should be split into understandable subexpressions using Extract Variable. If a comment explains a section of code, this section can be turned into a separate method via Extract Method. The name of the new method can be taken from the comment text itself, most likely. If a method has already been extracted, but comments are still necessary to explain what the method does, give the method a self-explanatory name. Use Rename Method for this. If you need to assert rules about a state that's necessary for the system to work, use Introduce Assertion.

### Duplicate Code

**Signs and symptoms:** Two code fragments look almost identical.

**Treatment:** If the same code is found in two or more methods in the same class: use Extract Method and place calls for the new method in both places. If the same code is found in two subclasses of the same level: Use Extract Method for both classes, followed by Pull Up Field for the fields used in the method that you're pulling up. If the duplicate code is inside a constructor, use Pull Up Constructor Body. If the duplicate code is similar but not completely identical, use Form Template Method. If two methods do the same thing but use different algorithms, select the best algorithm and apply Substitute Algorithm. If duplicate code is found in two different classes: If the classes aren't part of a hierarchy, use Extract Superclass in order to create a single superclass for these classes that maintains all the previous functionality. If it's difficult or impossible to create a superclass, use Extract Class in one class and use the new component in the other. If a large number of conditional expressions are present and perform the same code (differing only in their conditions), merge these operators into a single condition using Consolidate Conditional Expression and use Extract Method to place the condition in a separate method with an easy-to-understand name. If the same code is performed in all branches of a conditional expression: place the identical code outside of the condition tree by using Consolidate Duplicate Conditional Fragments.

### Lazy Class

**Signs and symptoms:** Understanding and maintaining classes always costs time and money. So if a class doesn't do enough to earn your attention, it should be deleted.

**Treatment:** Components that are near-useless should be given the Inline Class treatment. For subclasses with few functions, try Collapse Hierarchy.

### Data Class

**Signs and symptoms:** A data class refers to a class that contains only fields and crude methods for accessing them (getters and setters). These are simply containers for data used by other classes. These classes don't contain any additional functionality and can't independently operate on the data that they own.

**Treatment:** If a class contains public fields, use Encapsulate Field to hide them from direct access and require that access be performed via getters and setters only. Use Encapsulate Collection for data stored in collections (such as arrays). Review the client code that uses the class. In it, you may find functionality that would be better located in the data class itself. If this is the case, use Move Method and Extract Method to migrate this functionality to the data class. After the class has been filled with well thought-out methods, you may want to get rid of old methods for data access that give overly broad access to the class data. For this, Remove Setting Method and Hide Method may be helpful.

### Dead Code

**Signs and symptoms:** A variable, parameter, field, method or class is no longer used (usually because it's obsolete).

**Treatment:** The quickest way to find dead code is to use a good IDE. Delete unused code and unneeded files. In the case of an unnecessary class, Inline Class or Collapse Hierarchy can be applied if a subclass or superclass is used. To remove unneeded parameters, use Remove Parameter.

### Speculative Generality

**Signs and symptoms:** There's an unused class, method, field or parameter.

**Treatment:** For removing unused abstract classes, try Collapse Hierarchy. Unnecessary delegation of functionality to another class can be eliminated via Inline Class. Unused methods? Use Inline Method to get rid of them. Methods with unused parameters should be given a look with the help of Remove Parameter. Unused fields can be simply deleted.

## Couplers

### Feature Envy

**Signs and symptoms:** A method accesses the data of another object more than its own data.

**Treatment:** As a basic rule, if things change at the same time, you should keep them in the same place. Usually data and functions that use this data are changed together (although exceptions are possible). If a method clearly should be moved to another place, use Move Method. If only part of a method accesses the data of another object, use Extract Method to move the part in question. If a method uses functions from several other classes, first determine which class contains most of the data used. Then place the method in this class along with the other data. Alternatively, use Extract Method to split the method into several parts that can be placed in different places in different classes.

### Inappropriate Intimacy

**Signs and symptoms:** One class uses the internal fields and methods of another class.

**Treatment:** The simplest solution is to use Move Method and Move Field to move parts of one class to the class in which those parts are used. But this works only if the first class truly doesn't need these parts. Another solution is to use Extract Class and Hide Delegate on the class to make the code relations "official". If the classes are mutually interdependent, you should use Change Bidirectional Association to Unidirectional. If this "intimacy" is between a subclass and the superclass, consider Replace Delegation with Inheritance.

### Message Chains

**Signs and symptoms:** In code you see a series of calls resembling $a->b()->c()->d()

**Treatment:** To delete a message chain, use Hide Delegate. Sometimes it's better to think of why the end object is being used. Perhaps it would make sense to use Extract Method for this functionality and move it to the beginning of the chain, by using Move Method.

### Middle Man

**Signs and symptoms:** If a class performs only one action, delegating work to another class, why does it exist at all?

**Treatment:** If most of a method's classes delegate to another class, Remove Middle Man is in order.

## Other

### Incomplete Library Class

**Signs and symptoms:** Sooner or later, libraries stop meeting user needs. The only solution to the problem-changing the library-is often impossible since the library is read-only.

**Treatment:** To introduce a few methods to a library class, use Introduce Foreign Method. For big changes in a class library, use Introduce Local Extension.
